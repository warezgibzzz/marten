module Marten
  module DB
    module Management
      class Statement
        class ForeignKeyName < Reference
          def initialize(
            @index_name_proc : Proc(String, Array(String), String, String),
            @table : String,
            @column : String,
            @to_table : String,
            @to_column : String
          )
          end

          def rename_table(old_name : String, new_name : String)
            @table = new_name if @table == old_name
            @to_table = new_name if @to_table == new_name
          end

          def to_s
            IndexName.new(@index_name_proc, @table, [@column], "_fk_#{@to_table}_#{@to_column}").to_s
          end
        end
      end
    end
  end
end