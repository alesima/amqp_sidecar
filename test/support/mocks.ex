# test/support/mocks.ex
Mox.defmock(AmqpSidecar.Broker.Mock, for: AmqpSidecar.Broker)
Mox.defmock(AmqpSidecar.Http.Mock, for: AmqpSidecar.Http)
Mox.defmock(AmqpSidecar.Publisher.Mock, for: AmqpSidecar.PublisherBehaviour)
