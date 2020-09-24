require 'unisender_dna/sender'
require "unisender_dna/version"

module UnisenderDna
  module Installer
    extend self

    def install
      ActionMailer::Base.add_delivery_method :unisender_dna, UnisenderDna::Sender
    end
  end
end

UnisenderDna::Installer.install
