# Order processing map

Load this reference when a change affects order behavior shared by processing patterns.

| Pattern | Entry/implementation | Persistent behavior |
|---|---|---|
| State | `OrderService/Services/OrderProcessingServiceState.cs` | Direct Dapr state and pub/sub |
| Actor | `OrderService/Services/OrderProcessingServiceActor.cs` and `OrderService.Actors/Actors/OrderActor.cs` | Dapr actor state hosted separately |
| Workflow | `OrderService/Services/OrderProcessingServiceWorkflow.cs` and `OrderService/Workflows/` | Dapr workflow events and activities |

Also inspect the shared interface, controller mapping, order models, event publishing, pricing,
and existing unit tests. The router/default configuration determines which implementation runs
for a given order, but equivalent customer-visible behavior must remain consistent across all
supported patterns.

Do not change Dapr component names, state keys, event names, or serialized model shapes merely
to simplify a fix.
