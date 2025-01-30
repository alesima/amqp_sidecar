# test/support/mocks.ex
Mox.defmock(AMQP.Mock, for: AMQP.Connection)
Mox.defmock(AMQP.Mock, for: AMQP.Channel)
