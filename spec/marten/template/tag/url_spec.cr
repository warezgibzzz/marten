require "./spec_helper"

describe Marten::Template::Tag::Url do
  describe "::new" do
    it "raises if the url tag does not contain at least one argument" do
      parser = Marten::Template::Parser.new("{% url %}")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed url tag: at least one argument must be provided"
      ) do
        Marten::Template::Tag::Url.new(parser, "url")
      end
    end
  end

  describe "#render" do
    it "is able to returns the right URL for a view without arguments" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Url.new(parser, %{url "dummy"})
      tag.render(Marten::Template::Context.new).should eq Marten.routes.reverse(:dummy)
    end

    it "is able to returns the right URL for a view with arguments" do
      parser = Marten::Template::Parser.new("")

      tag_1 = Marten::Template::Tag::Url.new(parser, %{url "dummy_with_id" id: 42})
      tag_1.render(Marten::Template::Context.new).should eq Marten.routes.reverse(:dummy_with_id, id: 42)

      tag_2 = Marten::Template::Tag::Url.new(parser, %{url "dummy_with_id_and_scope" id: 42, scope: "ns"})
      tag_2.render(Marten::Template::Context.new).should eq(
        Marten.routes.reverse(:dummy_with_id_and_scope, id: 42, scope: "ns")
      )
    end

    it "is able to resolve route names from the context" do
      parser = Marten::Template::Parser.new("")

      tag_1 = Marten::Template::Tag::Url.new(parser, %{url rname id: 42})
      tag_1.render(Marten::Template::Context{"rname" => "dummy_with_id"}).should eq(
        Marten.routes.reverse(:dummy_with_id, id: 42)
      )

      tag_2 = Marten::Template::Tag::Url.new(parser, %{url rname id: 42, scope: "ns"})
      tag_2.render(Marten::Template::Context{"rname" => "dummy_with_id_and_scope"}).should eq(
        Marten.routes.reverse(:dummy_with_id_and_scope, id: 42, scope: "ns")
      )
    end

    it "is able to resolve route parameters from the context" do
      parser = Marten::Template::Parser.new("")

      tag_1 = Marten::Template::Tag::Url.new(parser, %{url "dummy_with_id" id: arg1})
      tag_1.render(Marten::Template::Context{"arg1" => 42}).should eq Marten.routes.reverse(:dummy_with_id, id: 42)

      tag_2 = Marten::Template::Tag::Url.new(parser, %{url "dummy_with_id_and_scope" id: 42, scope: "ns"})
      tag_2.render(Marten::Template::Context{"arg1" => 42, "arg2" => "ns"}).should eq(
        Marten.routes.reverse(:dummy_with_id_and_scope, id: 42, scope: "ns")
      )
    end

    it "raises if one of the resolved parameter does not have a valid parameter type" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Url.new(parser, %{url "dummy_with_id" id: arg})

      expect_raises(
        Marten::Template::Errors::UnsupportedType,
        "Hash(Marten::Template::Value, Marten::Template::Value) objects cannot be used as URL parameters"
      ) do
        tag.render(Marten::Template::Context{"arg" => {"foo" => "bar"}})
      end
    end
  end
end