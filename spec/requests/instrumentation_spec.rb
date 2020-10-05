require "rails_helper"

describe "Instrumentation" do
  let(:registry) { Prometheus::Client.registry }

  describe "process_action.action_controller" do
    after { get cookies_path }

    it "increments the :requests_total metric" do
      metric = registry.get(:requests_total)
      expect(metric).to receive(:increment).with(labels: { path: "/cookies", method: "GET", status: 200 }).once
    end

    it "observes the :request_duration_ms metric" do
      metric = registry.get(:request_duration_ms)
      expect(metric).to receive(:observe).with(instance_of(Float), labels: { path: "/cookies", method: "GET", status: 200 }).once
    end

    it "observes the :request_view_runtime_ms metric" do
      metric = registry.get(:request_view_runtime_ms)
      expect(metric).to receive(:observe).with(instance_of(Float), labels: { path: "/cookies", method: "GET", status: 200 }).once
    end
  end

  describe "render_template.action_view" do
    after { get cookie_preference_path }

    it "observes the :render_view_ms metric" do
      metric = registry.get(:render_view_ms)
      expect(metric).to receive(:observe).with(instance_of(Float), labels: {
        identifier: Rails.root.join("app/views/cookie_preferences/show.html.erb").to_s,
      }).once
    end
  end

  describe "render_partial.action_view" do
    after { get root_path }

    it "observes the :render_view_ms metric" do
      metric = registry.get(:render_partial_ms)
      allow(metric).to receive(:observe)
      expect(metric).to receive(:observe).with(instance_of(Float), labels: {
        identifier: Rails.root.join("app/views/sections/_head.html.erb").to_s,
      }).once
    end
  end

  describe "cache_read.active_support" do
    include_context "stub latest privacy policy api"

    after { get privacy_policy_path }

    it "observes the :cache_read_total metric" do
      metric = registry.get(:cache_read_total)
      expect(metric).to receive(:increment).with(labels: {
        key: instance_of(String),
        hit: false,
      }).once
    end
  end
end