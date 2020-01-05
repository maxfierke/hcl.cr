require "./spec_helper"

describe HCL do
  describe ".build" do
    it "outputs HCL from a built AST" do
      document = HCL.build do |hcl|
        hcl.attribute("version") { 1.2 }
        hcl.attribute("name") { "my-cool-project" }
        hcl.block("repository", "git") do |repo|
          repo.attribute("url") { "https://git.those.bytes/my-cool-project.git" }
        end
      end

      document.should eq(<<-HCL)
      version = 1.2
      name = "my-cool-project"

      repository "git" {
        url = "https://git.those.bytes/my-cool-project.git"
      }

      HCL
    end
  end
end
