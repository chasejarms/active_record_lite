require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    # ...
    where_clause = params.keys.map { |sym| "#{sym} = ?" }.join(" AND ")

    results = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_clause}
    SQL

    parse_all(results)
  end

end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
