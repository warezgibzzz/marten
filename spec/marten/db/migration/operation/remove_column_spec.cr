require "./spec_helper"

describe Marten::DB::Migration::Operation::RemoveColumn do
  describe "#describe" do
    it "returns the expected description" do
      operation = Marten::DB::Migration::Operation::RemoveColumn.new("operation_test_table", "test_column")
      operation.describe.should eq "Remove test_column on operation_test_table table"
    end
  end

  describe "#mutate_db_backward" do
    before_each do
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("operation_test_table")
        schema_editor.execute(schema_editor.delete_table_statement(schema_editor.quote("operation_test_table")))
      end
    end

    it "adds the column to the table" do
      column = Marten::DB::Management::Column::Int.new("foo", default: 42)

      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      from_project_state = Marten::DB::Management::ProjectState.new([from_table_state])

      to_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
          column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      to_project_state = Marten::DB::Management::ProjectState.new([to_table_state])

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::RemoveColumn.new("operation_test_table", "foo")

      operation.mutate_db_backward("my_app", schema_editor, from_project_state, to_project_state)

      Marten::DB::Connection.default.open do |db|
        last_column_checked = nil

        {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
          db.query("SHOW COLUMNS FROM operation_test_table") do |rs|
            rs.each do
              column_name = rs.read(String)
              last_column_checked = column_name
              next unless column_name == "foo"
              column_type = rs.read(String)
              column_type.should eq "int(11)"
            end
          end
        {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
          db.query(
            <<-SQL
              SELECT column_name, data_type
              FROM information_schema.columns
              WHERE table_name = 'operation_test_table'
            SQL
          ) do |rs|
            rs.each do
              column_name = rs.read(String)
              last_column_checked = column_name
              next unless column_name == "foo"
              column_type = rs.read(String)
              column_type.should eq "integer"
            end
          end
        {% else %}
          db.query("PRAGMA table_info(operation_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              column_name = rs.read(String)
              last_column_checked = column_name
              next unless column_name == "foo"
              column_type = rs.read(String)
              column_type.should eq "integer"
            end
          end
        {% end %}

        last_column_checked.should eq "foo"
      end
    end
  end

  describe "#mutate_db_forward" do
    before_each do
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("operation_test_table")
        schema_editor.execute(schema_editor.delete_table_statement(schema_editor.quote("operation_test_table")))
      end
    end

    it "removes the column from the table" do
      column = Marten::DB::Management::Column::Int.new("foo", default: 42)

      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
          column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      from_project_state = Marten::DB::Management::ProjectState.new([from_table_state])

      to_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      to_project_state = Marten::DB::Management::ProjectState.new([to_table_state])

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::RemoveColumn.new("operation_test_table", "foo")

      operation.mutate_db_forward("my_app", schema_editor, from_project_state, to_project_state)

      Marten::DB::Connection.default.open do |db|
        {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
          db.query("SHOW COLUMNS FROM operation_test_table") do |rs|
            rs.each do
              column_name = rs.read(String)
              column_name.should eq "id"
            end
          end
        {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
          db.query(
            <<-SQL
              SELECT column_name, data_type, is_nullable, column_default
              FROM information_schema.columns
              WHERE table_name = 'operation_test_table'
            SQL
          ) do |rs|
            rs.each do
              column_name = rs.read(String)
              column_name.should eq "id"
            end
          end
        {% else %}
          db.query("PRAGMA table_info(operation_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              column_name = rs.read(String)
              column_name.should eq "id"
            end
          end
        {% end %}
      end
    end
  end

  describe "#mutate_state_forward" do
    it "mutates a project state as expected" do
      column_to_remove = Marten::DB::Management::Column::Int.new("foo", default: 42)
      other_column = Marten::DB::Management::Column::BigAuto.new("id", primary_key: true)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [other_column, column_to_remove] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      operation = Marten::DB::Migration::Operation::RemoveColumn.new("operation_test_table", "foo")

      operation.mutate_state_forward("my_app", project_state)

      table_state.columns.should eq [other_column] of Marten::DB::Management::Column::Base
    end
  end

  describe "#serialize" do
    it "returns the expected serialized version of the operation" do
      operation = Marten::DB::Migration::Operation::RemoveColumn.new("operation_test_table", "foo")
      operation.serialize.strip.should eq %{remove_column :operation_test_table, :foo}
    end
  end
end