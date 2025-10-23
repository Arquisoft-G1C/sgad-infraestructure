# 🔔 SGAD Event-Driven Architecture

Real-time event communication system for SGAD using RabbitMQ and WebSockets.

---

## 📋 Overview

The event architecture enables:
- ✅ **Async communication** between microservices
- ✅ **Real-time updates** to frontend via WebSocket
- ✅ **Scheduled task notifications** (e.g., availability closing)
- ✅ **Decoupled service communication**
- ✅ **Event sourcing** and audit trails

---

## 🏗️ Architecture Components

### 1. **RabbitMQ Message Broker**
- **Port:** 5672 (AMQP)
- **Management UI:** http://localhost:15672
- **Credentials:** Set in `.env` file
- **Purpose:** Async message queuing and event publishing

### 2. **Redis Pub/Sub** (Alternative/Complementary)
- **Port:** 6379
- **Purpose:** Simple pub/sub for cache invalidation and quick notifications

### 3. **WebSocket Handler**
- **Endpoint:** `/ws/{user_id}`
- **Purpose:** Real-time event streaming to frontend clients

---

## 📊 Event Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Event Flow Diagram                        │
└─────────────────────────────────────────────────────────────┘

  Availability Service                    RabbitMQ                    Frontend
  (Publisher)                             (Broker)                    (Consumer)
       │                                     │                            │
       │  1. Scheduler runs                  │                            │
       │  (Friday 15:00)                     │                            │
       │                                     │                            │
       │  2. Close/Expire availability       │                            │
       │                                     │                            │
       │  3. Publish event ────────────────>│                            │
       │     "availability.closed"           │                            │
       │                                     │                            │
       │                                     │  4. Route to queue         │
       │                                     │     (by routing key)       │
       │                                     │                            │
       │                                     │  5. WebSocket consumer     │
       │                                     │     subscribes & receives  │
       │                                     │                            │
       │                                     │  6. Forward to WS ───────>│
       │                                     │                            │
       │                                     │                            │  7. Update UI
       │                                     │                            │     in real-time
```

---

## 📡 Event Types

### Availability Events
- `availability.closed` - Availability has been closed for the week
- `availability.expired` - Availability has expired
- `availability.updated` - Availability slots have been updated

### Notification Events
- `notification` - System notification (broadcast)

### Match Events (Future)
- `match.assigned` - Referee assigned to match
- `match.confirmed` - Referee confirmed assignment
- `match.cancelled` - Match cancelled

---

## 🔑 Exchange Configuration

### 1. **sgad.availability** (Topic Exchange)
Routes availability-related events using topic patterns.

**Routing Keys:**
- `availability.closed.{referee_id}`
- `availability.expired.{referee_id}`
- `availability.updated.{referee_id}`

**Consumers:**
- Frontend WebSocket handler (subscribes to `availability.#`)
- Match service (subscribes to `availability.updated.#`)
- Notification service (subscribes to all)

### 2. **sgad.notifications** (Fanout Exchange)
Broadcasts system notifications to all subscribers.

**Routing Keys:** None (fanout broadcasts to all)

**Consumers:**
- Frontend WebSocket handler
- Notification service

---

## 💻 Implementation Guide

### Step 1: Configure Environment

Add to your `.env` file:
```env
# RabbitMQ Configuration
RABBITMQ_USER=sgad_rabbit
RABBITMQ_PASSWORD=your_secure_password
RABBITMQ_VHOST=sgad_vhost
```

### Step 2: Start Services

```bash
cd sgad-infraestructure
docker-compose up -d rabbitmq
```

Access RabbitMQ Management UI:
```
http://localhost:15672
Username: sgad_rabbit
Password: (from .env)
```

### Step 3: Publish Events from Service

**In Availability Service:**

```python
from app.events.broker import get_event_broker
from datetime import datetime

# Get broker instance
broker = get_event_broker()

# Publish an event
broker.publish_availability_closed({
    "referee_id": "uuid-here",
    "week_number": 42,
    "closed_at": datetime.now().isoformat(),
    "total_slots": 7
})

# Or publish a notification
broker.publish_notification({
    "user_id": "referee-id-or-system",
    "title": "Disponibilidad Cerrada",
    "message": "Tu disponibilidad ha sido cerrada",
    "type": "info",
    "timestamp": datetime.now().isoformat()
})
```

### Step 4: Add WebSocket to FastAPI App

**In `main.py`:**

```python
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from app.events.websocket_handler import manager, get_consumer
from app.events.broker import get_event_broker, close_event_broker

app = FastAPI()

# Start RabbitMQ consumer on startup
@app.on_event("startup")
async def startup_event():
    get_consumer()  # Starts consuming events
    print("🎧 WebSocket consumer started")

# Close broker on shutdown
@app.on_event("shutdown")
async def shutdown_event():
    close_event_broker()
    print("🔌 Event broker closed")

# WebSocket endpoint
@app.websocket("/ws/{user_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    user_id: str
):
    await manager.connect(websocket, user_id)
    try:
        while True:
            # Keep connection alive and handle client messages
            data = await websocket.receive_text()
            await websocket.send_json({
                "type": "pong",
                "message": "Connection alive"
            })
    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)
```

### Step 5: Connect Frontend to WebSocket

**JavaScript/TypeScript Frontend:**

```typescript
// Connect to WebSocket
const userId = 'referee-uuid-here';
const ws = new WebSocket(`ws://localhost:8000/ws/${userId}`);

// Handle incoming events
ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  
  switch (message.event_type) {
    case 'availability.closed':
      console.log('Availability closed:', message);
      // Update UI: Show notification
      showNotification({
        title: 'Disponibilidad Cerrada',
        message: `Tu disponibilidad de la semana ${message.week_number} ha sido cerrada`,
        type: 'info'
      });
      break;
      
    case 'availability.updated':
      console.log('Availability updated:', message);
      // Update UI: Refresh availability list
      refreshAvailabilityList();
      break;
      
    case 'notification':
      console.log('Notification:', message);
      // Show notification
      showNotification(message);
      break;
  }
};

// Keep alive heartbeat
setInterval(() => {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send('ping');
  }
}, 30000);

// Handle connection errors
ws.onerror = (error) => {
  console.error('WebSocket error:', error);
};

ws.onclose = () => {
  console.log('WebSocket disconnected');
  // Implement reconnection logic
};
```

---

## 🔧 Advanced Usage

### Custom Event Publishing

```python
from app.events.broker import get_event_broker

broker = get_event_broker()

# Publish custom event with headers
broker.publish_event(
    exchange="sgad.availability",
    routing_key="custom.event.type",
    message={
        "event_type": "custom.event",
        "data": {"key": "value"},
        "timestamp": datetime.now().isoformat()
    },
    headers={"priority": "high"}
)
```

### Subscribe to Specific Events

```python
import pika
import json

# Connect to RabbitMQ
connection = pika.BlockingConnection(
    pika.ConnectionParameters(
        host='localhost',
        port=5672,
        credentials=pika.PlainCredentials('sgad_rabbit', 'password'),
        virtual_host='sgad_vhost'
    )
)
channel = connection.channel()

# Create queue
result = channel.queue_declare(queue='', exclusive=True)
queue_name = result.method.queue

# Bind to specific events
channel.queue_bind(
    exchange='sgad.availability',
    queue=queue_name,
    routing_key='availability.closed.*'  # Only closed events
)

# Consume
def callback(ch, method, properties, body):
    message = json.loads(body)
    print(f"Received: {message}")
    ch.basic_ack(delivery_tag=method.delivery_tag)

channel.basic_consume(queue=queue_name, on_message_callback=callback)
channel.start_consuming()
```

---

## 📊 Monitoring & Debugging

### RabbitMQ Management UI

Access at: http://localhost:15672

Features:
- 📊 View queues, exchanges, and bindings
- 📈 Monitor message rates
- 🔍 Debug message routing
- 👥 Manage users and permissions

### Check Message Flow

```bash
# List all queues
docker exec sgad-rabbitmq rabbitmqctl list_queues

# List all exchanges
docker exec sgad-rabbitmq rabbitmqctl list_exchanges

# List all bindings
docker exec sgad-rabbitmq rabbitmqctl list_bindings
```

### Test Event Publishing

```python
# Test script to publish events
from app.events.broker import EventBroker
from datetime import datetime

broker = EventBroker()
broker.connect()

broker.publish_notification({
    "user_id": "test-user",
    "title": "Test Notification",
    "message": "This is a test",
    "type": "info",
    "timestamp": datetime.now().isoformat()
})

print("✅ Test event published")
broker.disconnect()
```

---

## 🚀 Production Considerations

### 1. **Persistent Messages**
All events are published with `delivery_mode=2` (persistent).

### 2. **Dead Letter Queues**
Configure DLQ for failed message handling:
```python
channel.queue_declare(
    queue='availability-events',
    durable=True,
    arguments={
        'x-dead-letter-exchange': 'sgad.dlx',
        'x-message-ttl': 86400000  # 24 hours
    }
)
```

### 3. **Connection Pooling**
Use connection pooling for high-throughput:
```python
from pika import BlockingConnection
from pika.pool import QueuedPool

pool = QueuedPool(
    create=lambda: BlockingConnection(parameters),
    max_size=10,
    max_overflow=10
)
```

### 4. **Error Handling**
Always handle connection failures:
```python
from pika.exceptions import AMQPConnectionError

try:
    broker = get_event_broker()
    broker.publish_event(...)
except AMQPConnectionError as e:
    logger.error(f"Failed to publish event: {e}")
    # Fallback: Store in Redis or database for retry
```

### 5. **Monitoring**
- Set up CloudWatch/Prometheus metrics
- Monitor queue depths
- Alert on consumer lag
- Track message rates

---

## 🔗 Integration Examples

### Match Service (Consumer)

```python
# match-service: Listen for availability updates
import pika

def on_availability_updated(ch, method, properties, body):
    message = json.loads(body)
    referee_id = message['referee_id']
    
    # Update match assignments based on availability
    update_match_eligibility(referee_id)
    
    ch.basic_ack(delivery_tag=method.delivery_tag)

# Subscribe to availability updates
channel.queue_bind(
    exchange='sgad.availability',
    queue='match-service-queue',
    routing_key='availability.updated.#'
)
```

### Frontend React Hook

```typescript
// Custom hook for WebSocket events
import { useEffect, useState } from 'react';

export function useAvailabilityEvents(userId: string) {
  const [events, setEvents] = useState([]);
  const [ws, setWs] = useState<WebSocket | null>(null);

  useEffect(() => {
    const websocket = new WebSocket(`ws://localhost:8000/ws/${userId}`);
    
    websocket.onmessage = (event) => {
      const message = JSON.parse(event.data);
      setEvents(prev => [...prev, message]);
    };
    
    setWs(websocket);
    
    return () => websocket.close();
  }, [userId]);

  return { events, ws };
}
```

---

## 📚 Related Documentation

- [README.md](README.md) - Main infrastructure documentation
- [DATABASE_ARCHITECTURE.md](DATABASE_ARCHITECTURE.md) - Database design
- [RabbitMQ Documentation](https://www.rabbitmq.com/documentation.html)

---

## 🆘 Troubleshooting

### Problem: Events not being received

```bash
# Check RabbitMQ is running
docker-compose ps rabbitmq

# Check logs
docker-compose logs rabbitmq

# Verify connection
docker exec sgad-rabbitmq rabbitmqctl list_connections
```

### Problem: WebSocket disconnects frequently

- Implement reconnection logic in frontend
- Check network stability
- Increase heartbeat timeout
- Monitor for exceptions in backend logs

### Problem: Messages piling up in queue

- Check consumer is running
- Verify consumer processing speed
- Scale consumers horizontally
- Check for errors in message processing

---

**Happy Event-Driven Development! 🎉**

