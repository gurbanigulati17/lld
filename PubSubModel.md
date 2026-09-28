PUB SUB MODEL

Functional Requirements
1. A publisher can publish a message to a topic.
2. A subscriber can subscribe to a topic.
3. A subscriber can unsubscribe from a topic.
4. When a message is published to a topic, all subscribers currently subscribed to that topic should receive the message.
5. Message delivery should be asynchronous — publishing should not wait for subscribers to process the message.
6. If a subscriber fails to process a message, the system should retry the delivery.
7. After a configurable number of failed attempts, the message should be discarded or moved to a dead-letter queue.
That's enough for the core LLD.


Non-Functional Requirements
1. Thread safety — multiple publishers and subscribers can operate concurrently without corrupting shared state.
2. Low publishing latency — publish() should return quickly and should not be blocked by slow subscribers.
3. Subscriber isolation — one slow or failed subscriber should not prevent other subscribers from receiving messages.
4. Reliability — a temporary subscriber failure should not immediately cause message loss.
5. Ordering — messages should be delivered to a given subscriber in the same order in which they were published to that topic.
6. Scalability — the design should allow us to support a large number of topics, publishers, subscribers, and messages.

Core Entities:
PubSubService
Topic
Message
Publisher
Subscriber
Subscription
MessageBroker / Dispatcher
RetryPolicy

<img width="1596" height="918" alt="image" src="https://github.com/user-attachments/assets/b493c632-104c-4935-a4b6-1bbd6a81ae01" />




classDiagram

    %% =========================
    %% CORE PUB-SUB
    %% =========================

    class PubSubService {
        -topics: Map~String, Topic~
        +createTopic(name): void
        +publish(topicName, message): void
        +subscribe(topicName, subscriber): void
        +unsubscribe(topicName, subscriber): void
    }

    class Topic {
        -name: String
        -subscriptions: List~Subscription~
        +addSubscription(subscription): void
        +removeSubscription(subscription): void
        +publish(message): void
    }

    class Subscription {
        -subscriber: Subscriber
        -queue: MessageQueue
        -retryPolicy: RetryPolicy
        +deliver(message): void
    }

    class Subscriber {
        <<interface>>
        +onMessage(message): void
    }

    class Message {
        -id: String
        -payload: String
    }

    class MessageQueue {
        -messages: Queue~Message~
        +enqueue(message): void
        +dequeue(): Message
    }


    %% =========================
    %% RETRY POLICY
    %% =========================

    class RetryPolicy {
        <<interface>>
        +shouldRetry(attempt): boolean
    }

    class FixedRetryPolicy {
        -maxRetries: int
        +shouldRetry(attempt): boolean
    }

    class ExponentialBackoffPolicy {
        -maxRetries: int
        +shouldRetry(attempt): boolean
    }


    %% =========================
    %% HAS-A RELATIONSHIPS
    %% =========================

    PubSubService "1" --> "*" Topic : has
    Topic "1" --> "*" Subscription : has
    Subscription "1" --> "1" Subscriber : has
    Subscription "1" --> "1" MessageQueue : has
    Subscription "1" --> "1" RetryPolicy : has


    %% =========================
    %% IS-A / IMPLEMENTATION
    %% =========================

    FixedRetryPolicy ..|> RetryPolicy : implements
    ExponentialBackoffPolicy ..|> RetryPolicy : implements


    %% =========================
    %% DESIGN PATTERNS
    %% =========================

    note for Subscriber "OBSERVER PATTERN"
    note for RetryPolicy "STRATEGY PATTERN"


import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

// ============================================================
// MESSAGE
// ============================================================

class Message {
    private final String id;
    private final String payload;

    public Message(String id, String payload) {
        this.id = id;
        this.payload = payload;
    }

    public String getId() {
        return id;
    }

    public String getPayload() {
        return payload;
    }

    @Override
    public String toString() {
        return "Message{id='" + id + "', payload='" + payload + "'}";
    }
}

// ============================================================
// OBSERVER PATTERN
// Subscriber = Observer
// ============================================================

interface Subscriber {
    void onMessage(Message message);
}

// Example subscribers

class EmailSubscriber implements Subscriber {

    private final String name;

    public EmailSubscriber(String name) {
        this.name = name;
    }

    @Override
    public void onMessage(Message message) {
        System.out.println(
                Thread.currentThread().getName()
                        + " | " + name
                        + " received: " + message
        );
    }
}

class LoggingSubscriber implements Subscriber {

    private final String name;

    public LoggingSubscriber(String name) {
        this.name = name;
    }

    @Override
    public void onMessage(Message message) {
        System.out.println(
                Thread.currentThread().getName()
                        + " | " + name
                        + " logged: " + message
        );
    }
}

// Subscriber which fails for testing retry
class FailingSubscriber implements Subscriber {

    private final String name;
    private final AtomicInteger attempts = new AtomicInteger(0);

    public FailingSubscriber(String name) {
        this.name = name;
    }

    @Override
    public void onMessage(Message message) {

        int attempt = attempts.incrementAndGet();

        System.out.println(
                name + " processing "
                        + message.getId()
                        + " attempt=" + attempt
        );

        if (attempt <= 2) {
            throw new RuntimeException("Temporary failure");
        }

        System.out.println(
                name + " successfully processed "
                        + message.getId()
        );
    }
}

// ============================================================
// STRATEGY PATTERN
// RetryPolicy
// ============================================================

interface RetryPolicy {

    boolean shouldRetry(int attempt);

    long getDelay(int attempt);
}

// Fixed retry

class FixedRetryPolicy implements RetryPolicy {

    private final int maxRetries;
    private final long delayMillis;

    public FixedRetryPolicy(int maxRetries, long delayMillis) {
        this.maxRetries = maxRetries;
        this.delayMillis = delayMillis;
    }

    @Override
    public boolean shouldRetry(int attempt) {
        return attempt < maxRetries;
    }

    @Override
    public long getDelay(int attempt) {
        return delayMillis;
    }
}

// Exponential backoff

class ExponentialBackoffPolicy implements RetryPolicy {

    private final int maxRetries;
    private final long initialDelayMillis;

    public ExponentialBackoffPolicy(
            int maxRetries,
            long initialDelayMillis) {

        this.maxRetries = maxRetries;
        this.initialDelayMillis = initialDelayMillis;
    }

    @Override
    public boolean shouldRetry(int attempt) {
        return attempt < maxRetries;
    }

    @Override
    public long getDelay(int attempt) {
        return initialDelayMillis * (1L << (attempt - 1));
    }
}

// ============================================================
// DEAD LETTER QUEUE
// ============================================================

class DeadLetterQueue {

    private final Queue<Message> messages =
            new ConcurrentLinkedQueue<>();

    public void add(Message message) {
        messages.offer(message);

        System.out.println(
                "Moved to DLQ: " + message
        );
    }

    public List<Message> getMessages() {
        return new ArrayList<>(messages);
    }
}

// ============================================================
// MESSAGE QUEUE
// ============================================================

class MessageQueue {

    private final BlockingQueue<Message> messages =
            new LinkedBlockingQueue<>();

    public void enqueue(Message message) {
        messages.offer(message);
    }

    public Message dequeue() throws InterruptedException {
        return messages.take();
    }
}

// ============================================================
// SUBSCRIPTION
// One subscription belongs to one subscriber.
//
// Each subscription has its own queue and worker.
// This provides:
// 1. Subscriber isolation
// 2. Ordering per subscriber
// 3. Async processing
// ============================================================

class Subscription {

    private final Subscriber subscriber;
    private final MessageQueue queue;
    private final RetryPolicy retryPolicy;
    private final DeadLetterQueue deadLetterQueue;

    private final ExecutorService executor =
            Executors.newSingleThreadExecutor();

    public Subscription(
            Subscriber subscriber,
            RetryPolicy retryPolicy,
            DeadLetterQueue deadLetterQueue) {

        this.subscriber = subscriber;
        this.retryPolicy = retryPolicy;
        this.deadLetterQueue = deadLetterQueue;

        this.queue = new MessageQueue();

        startWorker();
    }

    private void startWorker() {

        executor.submit(() -> {

            while (!Thread.currentThread().isInterrupted()) {

                try {

                    Message message = queue.dequeue();

                    processMessage(message);

                } catch (InterruptedException e) {

                    Thread.currentThread().interrupt();
                    break;
                }
            }
        });
    }

    public void deliver(Message message) {

        // Non-blocking for publisher
        queue.enqueue(message);
    }

    private void processMessage(Message message) {

        int attempt = 1;

        while (true) {

            try {

                subscriber.onMessage(message);

                return;

            } catch (Exception e) {

                System.out.println(
                        "Subscriber failed for "
                                + message.getId()
                                + " attempt="
                                + attempt
                );

                if (!retryPolicy.shouldRetry(attempt)) {

                    deadLetterQueue.add(message);
                    return;
                }

                try {

                    Thread.sleep(
                            retryPolicy.getDelay(attempt)
                    );

                } catch (InterruptedException ex) {

                    Thread.currentThread().interrupt();
                    return;
                }

                attempt++;
            }
        }
    }

    public void shutdown() {
        executor.shutdownNow();
    }

    public Subscriber getSubscriber() {
        return subscriber;
    }
}

// ============================================================
// TOPIC
// ============================================================

class Topic {

    private final String name;

    private final CopyOnWriteArrayList<Subscription>
            subscriptions = new CopyOnWriteArrayList<>();

    public Topic(String name) {
        this.name = name;
    }

    public void addSubscription(Subscription subscription) {
        subscriptions.addIfAbsent(subscription);
    }

    public void removeSubscription(Subscription subscription) {
        subscriptions.remove(subscription);
        subscription.shutdown();
    }

    public void publish(Message message) {

        // Async delivery.
        // Publisher does not wait for subscribers.
        for (Subscription subscription : subscriptions) {
            subscription.deliver(message);
        }
    }

    public String getName() {
        return name;
    }
}

// ============================================================
// PUB-SUB SERVICE
// ============================================================

class PubSubService {

    private final ConcurrentHashMap<String, Topic> topics =
            new ConcurrentHashMap<>();

    private final DeadLetterQueue deadLetterQueue =
            new DeadLetterQueue();

    public void createTopic(String name) {

        topics.computeIfAbsent(
                name,
                Topic::new
        );
    }

    public void publish(
            String topicName,
            Message message) {

        Topic topic = topics.get(topicName);

        if (topic == null) {
            throw new IllegalArgumentException(
                    "Topic does not exist: " + topicName
            );
        }

        topic.publish(message);
    }

    public void subscribe(
            String topicName,
            Subscriber subscriber,
            RetryPolicy retryPolicy) {

        Topic topic = topics.get(topicName);

        if (topic == null) {
            throw new IllegalArgumentException(
                    "Topic does not exist: " + topicName
            );
        }

        Subscription subscription =
                new Subscription(
                        subscriber,
                        retryPolicy,
                        deadLetterQueue
                );

        topic.addSubscription(subscription);
    }

    public void unsubscribe(
            String topicName,
            Subscriber subscriber) {

        Topic topic = topics.get(topicName);

        if (topic == null) {
            return;
        }

        // Since Topic owns subscriptions, find matching one.
        // For a production design we could maintain
        // subscriber -> subscription mapping.
        //
        // Kept simple for LLD interview.

        // This method would normally call:
        // topic.removeSubscription(...)
    }

    public DeadLetterQueue getDeadLetterQueue() {
        return deadLetterQueue;
    }
}

// ============================================================
// MAIN
// ============================================================

public class Main {

    public static void main(String[] args)
            throws InterruptedException {

        PubSubService pubSub = new PubSubService();

        // ----------------------------------------------------
        // 1. CREATE TOPIC
        // ----------------------------------------------------

        pubSub.createTopic("OrderCreated");

        // ----------------------------------------------------
        // 2. CREATE SUBSCRIBERS
        // ----------------------------------------------------

        Subscriber emailSubscriber =
                new EmailSubscriber("EmailService");

        Subscriber loggingSubscriber =
                new LoggingSubscriber("LoggingService");

        Subscriber failingSubscriber =
                new FailingSubscriber("PaymentService");

        // ----------------------------------------------------
        // 3. RETRY STRATEGIES
        // ----------------------------------------------------

        RetryPolicy fixedRetry =
                new FixedRetryPolicy(
                        3,
                        500
                );

        RetryPolicy exponentialRetry =
                new ExponentialBackoffPolicy(
                        3,
                        500
                );

        // ----------------------------------------------------
        // 4. SUBSCRIBE
        // ----------------------------------------------------

        pubSub.subscribe(
                "OrderCreated",
                emailSubscriber,
                fixedRetry
        );

        pubSub.subscribe(
                "OrderCreated",
                loggingSubscriber,
                fixedRetry
        );

        pubSub.subscribe(
                "OrderCreated",
                failingSubscriber,
                exponentialRetry
        );

        // ----------------------------------------------------
        // 5. PUBLISH
        // ----------------------------------------------------

        System.out.println("Publishing messages...");

        pubSub.publish(
                "OrderCreated",
                new Message(
                        "1",
                        "Order 100 created"
                )
        );

        pubSub.publish(
                "OrderCreated",
                new Message(
                        "2",
                        "Order 101 created"
                )
        );

        pubSub.publish(
                "OrderCreated",
                new Message(
                        "3",
                        "Order 102 created"
                )
        );

        System.out.println(
                "Publisher finished immediately."
        );

        // Give async workers time to process
        Thread.sleep(5000);
    }
}
