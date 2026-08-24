import { defineStore } from 'pinia'
import apiClient from '@/store/apiClient'
import * as signalR from '@microsoft/signalr'

export const useKitchenStore = defineStore('kitchen', {
  state: () => ({
    pendingOrders: [],
    signalRHubConnection: null,
    signalRRetryTimer: null,
    signalRRefreshRetryTimer: null,
  }),
  getters: {
    pendingOrdersList: (state) => state.pendingOrders,
  },
  actions: {
    async fetchPendingOrders() {
      const response = await apiClient.getPendingOrders()
      this.pendingOrders = response.data
    },
    async fetchOrderAndUpdateStore(orderId) {
      try {
        const response = await apiClient.getPendingOrder(orderId)
        const idx = this.pendingOrders.findIndex(o => o.id === orderId)
        if (idx !== -1) this.pendingOrders[idx] = response.data
        else this.pendingOrders.push(response.data)
      } catch (error) {
        if (error.response && error.response.status === 404) {
          this.pendingOrders = this.pendingOrders.filter(o => o.id !== orderId)
        } else {
          console.error('Error fetching pending order:', error)
        }
      }
    },
    async finishOrderItem(itemId) {
      try {
        await apiClient.finishOrderItem(itemId)
      } catch (e) {
        console.error('Error finishing order item:', e)
        throw e
      }
    },
    async initializeSignalRHub({ onStateChange, onUpdateError } = {}) {
      if (this.signalRHubConnection) return

      const connection = new signalR.HubConnectionBuilder()
        .withUrl('/kitchenorderupdatehub')
        .withAutomaticReconnect([0, 2000, 5000, 10000, 30000])
        .build()

      const subscribeAndRefresh = async () => {
        await connection.invoke('SubscribeToWork')
        await this.fetchPendingOrders()
      }

      const scheduleStartupRetry = () => {
        clearTimeout(this.signalRRetryTimer)
        this.signalRRetryTimer = setTimeout(startConnection, 5000)
      }

      const scheduleRefreshRetry = () => {
        clearTimeout(this.signalRRefreshRetryTimer)
        this.signalRRefreshRetryTimer = setTimeout(retryRefresh, 5000)
      }

      const retryRefresh = async () => {
        if (connection.state !== signalR.HubConnectionState.Connected) {
          scheduleStartupRetry()
          return
        }

        onStateChange?.('connecting')
        try {
          await subscribeAndRefresh()
          onStateChange?.('live')
        } catch (error) {
          console.error('Error retrying kitchen queue refresh:', error)
          onStateChange?.('offline')
          onUpdateError?.()
          scheduleRefreshRetry()
        }
      }

      const startConnection = async () => {
        if (connection.state !== signalR.HubConnectionState.Disconnected) return
        onStateChange?.('connecting')
        try {
          await connection.start()
          await subscribeAndRefresh()
          onStateChange?.('live')
        } catch (error) {
          console.error('Error starting kitchen updates:', error)
          onStateChange?.('offline')
          if (connection.state === signalR.HubConnectionState.Connected) scheduleRefreshRetry()
          else scheduleStartupRetry()
        }
      }

      // Refresh the full list on updates; avoids stale items when an order closes.
      connection.on('kitchenorderupdated', async () => {
        try {
          await this.fetchPendingOrders()
          onStateChange?.('live')
        } catch (error) {
          console.error('Error refreshing live kitchen orders:', error)
          onStateChange?.('offline')
          onUpdateError?.()
          scheduleRefreshRetry()
        }
      })
      connection.onreconnecting(() => onStateChange?.('connecting'))
      connection.onreconnected(async () => {
        try {
          await subscribeAndRefresh()
          onStateChange?.('live')
        } catch (error) {
          console.error('Error restoring kitchen updates:', error)
          onStateChange?.('offline')
          onUpdateError?.()
          scheduleRefreshRetry()
        }
      })
      connection.onclose(() => {
        clearTimeout(this.signalRRefreshRetryTimer)
        onStateChange?.('offline')
        scheduleStartupRetry()
      })

      this.signalRHubConnection = connection
      await startConnection()
    },
  }
})
