import { defineStore } from 'pinia'
import apiClient from '@/store/apiClient'
import * as signalR from '@microsoft/signalr'

export const useOrderStatusStore = defineStore('orderStatus', {
  state: () => ({
    ordersInPreparation: [],
    ordersFinished: [],
    signalRHubConnection: null,
    signalRRetryTimer: null,
  }),
  getters: {
    ordersInPreparationList: (s) => s.ordersInPreparation,
    ordersFinishedList: (s) => s.ordersFinished,
  },
  actions: {
    updateOrder(updatedOrder) {
      this.ordersInPreparation = this.ordersInPreparation.filter(o => o.id !== updatedOrder.id)
      this.ordersFinished = this.ordersFinished.filter(o => o.id !== updatedOrder.id)
      if (updatedOrder.type !== 'Inhouse') return
      switch (updatedOrder.state) {
        case 'Paid':
        case 'Processing':
          this.ordersInPreparation.push(updatedOrder)
          break
        case 'Closed':
        case 'Prepared':
          this.ordersFinished.push(updatedOrder)
          if (this.ordersFinished.length > 10) this.ordersFinished.shift()
          break
      }
    },
    removeOrder(orderId) {
      this.ordersInPreparation = this.ordersInPreparation.filter(o => o.id !== orderId)
      this.ordersFinished = this.ordersFinished.filter(o => o.id !== orderId)
    },
    async fetchOrderAndUpdateStore(orderId) {
      try {
        const response = await apiClient.getOrder(orderId)
        this.updateOrder(response.data)
      } catch (error) {
        if (error.response && error.response.status === 404) this.removeOrder(orderId)
        else {
          console.error('Error fetching pending order:', error)
          throw error
        }
      }
    },
    async initializeSignalRHub({ onStateChange, onUpdateError } = {}) {
      if (this.signalRHubConnection) return

      const connection = new signalR.HubConnectionBuilder()
        .withUrl('/orderupdatehub')
        .withAutomaticReconnect([0, 2000, 5000, 10000, 30000])
        .build()

      const subscribe = () => connection.invoke('SubscribeToOrderUpdates')

      const scheduleStartupRetry = () => {
        clearTimeout(this.signalRRetryTimer)
        this.signalRRetryTimer = setTimeout(startConnection, 5000)
      }

      const startConnection = async () => {
        if (connection.state !== signalR.HubConnectionState.Disconnected) return
        onStateChange?.('connecting')
        try {
          await connection.start()
          await subscribe()
          onStateChange?.('live')
        } catch (error) {
          console.error('Error starting order status updates:', error)
          onStateChange?.('offline')
          scheduleStartupRetry()
        }
      }

      connection.on('ReceiveOrderUpdate', async (order) => {
        try {
          await this.fetchOrderAndUpdateStore(order.id)
          onStateChange?.('live')
        } catch {
          onStateChange?.('offline')
          onUpdateError?.()
        }
      })
      connection.onreconnecting(() => onStateChange?.('connecting'))
      connection.onreconnected(async () => {
        try {
          await subscribe()
          onStateChange?.('live')
        } catch (error) {
          console.error('Error restoring order status updates:', error)
          onStateChange?.('offline')
          onUpdateError?.()
        }
      })
      connection.onclose(() => {
        onStateChange?.('offline')
        scheduleStartupRetry()
      })

      this.signalRHubConnection = connection
      await startConnection()
    },
  }
})
