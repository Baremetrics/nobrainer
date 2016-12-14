class NoBrainer::QueryRunner::Driver < NoBrainer::QueryRunner::Middleware
  def call(env)
    options = env[:options]
    options = options.merge(:db => RethinkDB::RQL.new.db(options[:db])) if options[:db]

    RDB::Pool.instance.with do |connection|
      env[:query].run(connection, options)
    end
  end
end
