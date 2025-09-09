require "bosh/template/test"
require "yaml"

describe "gremlind job" do
  let(:release) { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '..')) }
  let(:job) { release.job('gremlind') }
  let(:template) { job.template('config.yaml') }

  context "when service_url, team_id, and tags are provided" do
    let(:manifest) do
      {
        "gremlin" => {
          "service_url" => "https://url.com/v1",
          "team_id" => "team-123",
          "tags" => { "env" => "prod", "role" => "test" }
        }
      }
    end

    it "renders service_url" do
      rendered = YAML.safe_load(template.render(manifest))
      expect(rendered["service_url"]).to eq("https://url.com/v1")
    end

    it "renders team_id" do
      rendered = YAML.safe_load(template.render(manifest))
      expect(rendered["team_id"]).to eq("team-123")
    end

    it "renders tags as a hash" do
      rendered = YAML.safe_load(template.render(manifest))
      expect(rendered["tags"]).to eq({ "env" => "prod", "role" => "test" })
    end
  end

  context "when identifier is missing or empty" do
    let(:manifest) { { "gremlin" => { "identifier" => "" } } }
    let(:spec) { { "name" => "gremlind", "id" => "123" } }

    it "renders identifier with default fallback" do
      rendered = YAML.safe_load(template.render(manifest, spec: spec))
      expect(rendered["identifier"]).to eq("gremlind-123")
    end
  end

  context "when team_secret or team_certificate/team_private_key are provided" do
    it "renders team_secret" do
      manifest = { "gremlin" => { "team_secret" => "secret" } }
      rendered = YAML.safe_load(template.render(manifest))
      expect(rendered["team_secret"]).to eq("secret")
    end

    it "renders inline team_certificate and team_private_key" do
      manifest = { "gremlin" => { "team_certificate" => "-----BEGIN CERTIFICATE-----\nabc\n-----BEGIN CERTIFICATE-----\n", "team_private_key" => "-----BEGIN EC PRIVATE KEY-----\nabc\n-----END EC PRIVATE KEY-----\n" } }
      rendered = YAML.safe_load(template.render(manifest))
      expect(rendered["team_certificate"]).to eq("-----BEGIN CERTIFICATE-----\nabc\n-----BEGIN CERTIFICATE-----\n")
      expect(rendered["team_private_key"]).to eq("-----BEGIN EC PRIVATE KEY-----\nabc\n-----END EC PRIVATE KEY-----\n")
    end

    it "renders team_certificate and team_private_key as a filepath" do
      manifest = { "gremlin" => { "team_certificate" => "file:///path/to/my/cert", "team_private_key" => "file:///path/to/my/key" } }
      rendered = YAML.safe_load(template.render(manifest))
      expect(rendered["team_certificate"]).to eq("file:///path/to/my/cert")
      expect(rendered["team_private_key"]).to eq("file:///path/to/my/key")
    end
  end

  context "when ssl_cert_file is provided" do
    it "renders as inline certificate" do
      manifest = { "gremlin" => { "ssl_cert_file" => "-----BEGIN CERTIFICATE-----\nabc\n-----BEGIN CERTIFICATE-----\n" } }
      rendered = YAML.safe_load(template.render(manifest))
      expect(rendered["ssl_cert_file"]).to eq("-----BEGIN CERTIFICATE-----\nabc\n-----BEGIN CERTIFICATE-----\n")
    end

    it "renders as a filepath" do
      manifest = { "gremlin" => { "ssl_cert_file" => "file:///path/to/my/certfile.pem" } }
      rendered = YAML.safe_load(template.render(manifest))
      expect(rendered["ssl_cert_file"]).to eq("file:///path/to/my/certfile.pem")
    end
  end

  context "when push_metrics, collect_processes, collect_dns are provided" do
    let(:manifest) do
      {
        "gremlin" => {
          "push_metrics" => true,
          "collect_processes" => false,
          "collect_dns" => true
        }
      }
    end

    it "renders push_metrics" do
      rendered = YAML.safe_load(template.render(manifest))
      expect(rendered["push_metrics"]).to eq(true)
    end

    it "renders collect_processes" do
      rendered = YAML.safe_load(template.render(manifest))
      expect(rendered["collect_processes"]).to eq(false)
    end

    it "renders collect_dns" do
      rendered = YAML.safe_load(template.render(manifest))
      expect(rendered["collect_dns"]).to eq(true)
    end
  end

  context "when iam_role is present" do
    let(:manifest) { { "gremlin" => { "iam_role" => "role-arn" } } }

    it "renders iam_role" do
      rendered = YAML.safe_load(template.render(manifest))
      expect(rendered["iam_role"]).to eq("role-arn")
    end
  end
end