module Marten
  module DB
    abstract class Migration
      module Column
        class BigInt < Base
          include IsBuiltInColumn
        end
      end
    end
  end
end