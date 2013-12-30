require "projsync/version"
require 'grit'
require 'colorize'


module Projsync

	class Project
		attr_accessor :name
		attr_accessor :group
		attr_accessor :path
		attr_accessor :origin

		# the block passed in is run when the project syncs
		# options:
		# * origin
		def initialize(group, name, options = {}, &block)
			@name = name
			@group = group
			@path = options[:path] || name
			@origin = options[:origin]
			@sync_block = block
		end


		def dir_path
			fp = self.path
			fp = File.join(self.group.dir_path, fp) if self.group
			File.expand_path(fp)
		end


		def exist?
			File.exist? self.dir_path
		end


		def repo
			Grit::Repo.new(self.dir_path)
		end


		def repo_dirty?
			`cd #{dir_path} && git status --porcelain` == ""
		end


		def log(type, text)
			text = "[#{name_path}] #{text}"
			case type
			when :action
				puts text.green
			when :status
				puts text.yellow
			when :error
				puts text.red
			else
				raise ArgumentError, "Unknown log typ '#{type}'"
			end
		end


		def name_path
			if self.group && self.group.name_path && self.group.name_path.length
				self.group.name_path + '/' + self.name
			else
				self.name
			end
		end


		def sync(dry_run = false)
			if exist?
				if repo_dirty?
					log :status, "Repo dirty, not fetching"
				else
					log :action, "Fetching..."
					system("cd #{dir_path} && git fetch")

					#TODO: pull
					#TODO: run sync block
					# 	@sync_block.call() if @sync_block
				end

				#TODO: push
			else
				if origin
					log :action, "Project not present, cloning from origin..."
					system("mkdir #{dir_path} && cd #{dir_path} && git clone #{origin}")
				else
					log :error, "Project not present, specify an origin in projfile and resync"
				end
			end
		end


		def inspect(indent = 0)
			"#{'  ' * indent}Project: '#{self.name}'\n"
		end
	end



	class Group
		attr_accessor :parent
		attr_accessor :subgroups
		attr_accessor :projects

		attr_accessor :name
		attr_accessor :default
		attr_accessor :path


		def initialize(parent, name, options = {})
			options = {
				default: true,
				path: name
			}.merge(options)

			@name = name
			@parent = parent
			@default = options[:default]
			@path = options[:path]
		end


		def subgroups
			@subgroups ||= []
		end


		def projects
			@projects ||= []
		end

		def name_path
			if self.parent && self.parent.name
				self.parent.name_path + '/' + self.name
			else
				self.name
			end
		end


		def dir_path
			self.parent.nil? || self.parent.dir_path.nil? ? self.path : self.parent.dir_path + '/' + self.path
		end


		def sync(options = {}, blacklist = [], whitelist = [])
			np = self.name_path
			if (self.default or whitelist.include? np) and !blacklist.include? np
				self.projects.each { |proj| proj.sync(options) }
			end

			self.subgroups.each do|subgroup|
				subgroup.sync(options, blacklist, whitelist)
			end
		end


		def inspect(indent = 0)
			i = '  ' * indent
			desc = ""
			desc += "#{i}Group: '#{self.name}'\n"

			if self.projects.length > 0
				desc = self.projects.inject(desc) do |desc, proj|
					desc + proj.inspect(indent + 1)
				end
			end

			if self.subgroups.length > 0
				desc = self.subgroups.inject(desc) do |desc, group|
					desc + group.inspect(indent + 1)
				end
			end

			desc
		end
	end



	class Manifest
		def initialize
			@tree = Group.new(nil, nil, default: true)	# root group
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


		def sync(options = {}, blacklist = [], whitelist = [])
			@tree.sync(blacklist, whitelist)
		end


		def inspect
			@tree.subgroups.inject("") do |desc, group|
				desc + group.inspect(1)
			end
		end
	end
end
