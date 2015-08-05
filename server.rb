require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/json'
require 'octokit'
require 'oj'
require 'multi_json'
require 'highline/import'
require 'yaml'

def ask_access_token(prompt="Enter Your Access Token")
  ask(prompt) { |q| q.echo = false }
end

CONFIG = YAML.load_file(File.expand_path('../config/app.yml', __FILE__))
CLIENT = Octokit::Client.new \
  access_token: ask_access_token,
  auto_paginate: true

get '/' do
  json({
    status: "ok",
    response: {
      endpoints: [
        '/repos/:owner/:repo/issues/:id'
      ]
    }
  })
end

get '/repos/:owner/:repo/issues/:id' do
  repo = "#{params[:owner]}/#{params[:repo]}"

  unless CONFIG['valid_repos'].key?(params[:owner]) and
         CONFIG['valid_repos'][params[:owner]].include?(params[:repo])

    status 403
    json({
      status: "error",
      message: "We don't support '#{repo}' yet."
    })

  else
    begin
      res = CLIENT.issue(repo, params[:id])
      json({
        status: "ok",
        response: res
      })
    rescue Octokit::NotFound => e
      json({
        status: "error",
        message: "can not find issue(#{params[:id]}) under #{repo}."
      })
    rescue Octokit::Unauthorized => e
      json({
        status: "error",
        message: "github unauthorized. please contact @agate!"
      })
    rescue => e
      status 500
      json({
        status: "error",
        message: "unknown exception"
      })

      puts [
        Time.now.to_s,
        "ERROR",
        "/repos/#{params[:owner]}/#{params[:repo]}/issues/#{params[:id]}",
        MultiJson.dump(params),
        e.inspect
      ].join("\t")
    end
  end
end
