# AWS SQS / AWS SNS

**Key Differences Between AWS SNS and AWS SQS**
| Feature | AWS SQS | AWS SNS |
| --- | --- | --- |
| Messaging Pattern | Queue (Point-to-Point): One producer, one consumer per message. | Publish/Subscribe (Pub/Sub): One producer, multiple subscribers receive each message. |
| Message Delivery | Pull-Based: Consumers poll the queue to retrieve messages when ready. | Push-Based: Messages are pushed to subscribers as they are published. |
| Message Persistence | Messages are stored in the queue until they are processed and deleted by consumers. | Messages are not stored; they are delivered to subscribers and then discarded. |
| Delivery Guarantee | At-Least-Once: Messages are delivered at least once; duplicates are possible. | Best-Effort: Attempts to deliver messages to all subscribers; no built-in retry for failed deliveries unless configured. |
| Message Ordering | Supports FIFO queues for strict message ordering. | Does not guarantee message order; messages may arrive out of sequence. |
| Use Case Focus | Decoupling components and buffering messages for asynchronous processing by a single consumer per message. | Broadcasting messages to multiple subscribers or triggering multiple downstream processes simultaneously. |
