require "projsync/version"
require 'grit'


module Projsync

	class Project
		attr_accessor :group


		# the block passed in is run when the project syncs
		# options:
		# * origin
		def initialize(group, name, options = {}, &block)
			@group = group
			@path = options[:path] || name
			@origin = options[:origin]
			@sync_block = block
		end
		

		def repo_path
			fp = self.path
			fp = File.join(self.group.path, fp) if self.group
			File.expand_path(fp)
		end


		def git_repo
			Grit::Repo.new(self.repo_path)
		end


		def sync(dry_run = false)
			
			#FIXME: if it doesn't exist, clone it from origin if specified


			r = self.git_repo

			if !r.dirty?
				r.fetch()
				r.pull()

				@sync_block.call() if @sync_block

				puts "Fetched, pulled, and ran sync block"
			else
				puts "Repo was dirty, so skipping fetch/pull"
			end
		end

	end



	class Group
		attr_accessor :parent
		attr_accessor :subgroups
		attr_accessor :projects

		attr_accessor :default


		def initialize(parent, name, options = {})
			@parent = parent
			@default = options[:default]
			@path = options[:path] || name
		end


		def projects
			@projects ||= []
		end
	end



	class Manifest
		def initialize
			@tree = Group.new(nil, default: true)	# root group
			@top_group = @tree
		end


		def group(path, options = {}, &block)
			g = Group.new(@top_group, path, options)
			@top_group.subgroups << g
			@top_group = g

			yield

			@top_group = @top_group.parent
		end


		def project(path, options = {}, &block)
			@top_group.projects << Project.new(@top_group, path, options, &block)
		end

	end
end
