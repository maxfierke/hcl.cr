require "../spec_helper"

describe HCL::Builder do
  it "can build a document" do
    builder = HCL::Builder.build do |hcl|
      hcl.attribute("hello") { "world" }
      hcl.attribute("life") { 42 }
      hcl.attribute("contrived") { true }
      hcl.attribute("nothing") { nil }

      hcl.block("a_block") do |b|
        b.attribute("title") { "Isn't this grand" }
        b.attribute("fruits") do |attr|
          attr.list do |l|
            l << "hello"
            l << 27
            l << true
          end
        end
        b.attribute("veggies") do
          [
            "kale",
            "zuccini",
            "carrot",
            4,
            false
          ]
        end
      end

      hcl.block("b_block", "one", "point-one") do |b|
        b.attribute("title") { "Well I suppose" }
        b.attribute("hash_map") do |attr|
          attr.map do |m|
            m.attribute("potatoes") { "yes" }
            m.attribute("corned_beef") { "yes" }
            m.attribute("pizza") { "no" }
          end
        end
        b.attribute("world_map") do
          {
            "usa" => "maybe",
            "france" => "i suppose",
            "finland" => "yes",
            "tierra_del_fuego" => "could be"
          }
        end
      end

      hcl.block("empty_block") {}
    end

    builder.to_s.should eq(<<-HCL)
    hello = "world"
    life = 42
    contrived = true
    nothing = null

    a_block {
      title = "Isn't this grand"
      fruits = ["hello", 27, true]
      veggies = ["kale", "zuccini", "carrot", 4, false]
    }

    b_block "one" "point-one" {
      title = "Well I suppose"
      hash_map = {
        potatoes = "yes",
        corned_beef = "yes",
        pizza = "no"
      }
      world_map = {
        usa = "maybe",
        france = "i suppose",
        finland = "yes",
        tierra_del_fuego = "could be"
      }
    }

    empty_block {}

    HCL
  end
end
