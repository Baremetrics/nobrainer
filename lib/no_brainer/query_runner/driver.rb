class NoBrainer::QueryRunner::Driver < NoBrainer::QueryRunner::Middleware
  def call(env)
    instrument_metrics(env) do
      RDB::Pool.instance.with do |connection|
        options = env[:options]
        options = options.merge(:db => RethinkDB::RQL.new.db(options[:db])) if options[:db]

        env[:query].run(connection, options)
      end
    end
  end

  def instrument_metrics(env)
    query = RethinkDB::RPP.pp(env[:query]).truncate(150)
    table_regex = /(?<=table\(\")(.*?)(?=\")/
    table_name = query[table_regex]

    yield
  end
end
