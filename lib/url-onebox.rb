#encoding: utf-8

libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
$project_root = File.expand_path(File.dirname(__FILE__) + '/../')

require 'mustache'
require 'nokogiri'
require 'active_support'
require 'active_support/dependencies'

require 'oneboxer/base'
require 'oneboxer/whitelist'
Dir["#{$project_root}/lib/oneboxer/*_onebox.rb"].each {|f|
  require (f.split('/')[-2..-1].join('/'))
}


module UrlOnebox
	extend Oneboxer::Base

	Dir["#{$project_root}/lib/oneboxer/*_onebox.rb"].each do |f|
	    add_onebox "Oneboxer::#{Pathname.new(f).basename.to_s.gsub(/\.rb$/, '').classify}".constantize
	end

	def self.delete_cache(url) end
	def self.render_from_cache(url, args={}) nil end
	def self.render_save_cache(url, cooked) end

	# 匹配指定的URL，尝试生成和返回一个onebox实例
	# 这是针对特别编写的onebox代码而设
	def self.onebox_for_url(url)
		matchers.each do |regexp, oneboxer|
			regexp = regexp.call if regexp.class == Proc
			return oneboxer.new(url) if url =~ regexp
		end
		nil
	end

	# 匹配指定的URL，尝试生成和返回一个onebox实例
	# 包括上面的onebox_for_url，还检查oEmbed内的onebox
	def self.onebox_nocache(url)
	    oneboxer = onebox_for_url(url)
	    return oneboxer.onebox if oneboxer.present?

	    whitelist_entry = Whitelist.entry_for_url(url)

	    if whitelist_entry.present?
	      page_html = open(url).read
	      if page_html.present?
		doc = Nokogiri::HTML(page_html)

		# 从oEmbed协议中取onebox
		if whitelist_entry.allows_oembed?
		  (doc/"link[@type='application/json+oembed']").each do |oembed|
		    return OembedOnebox.new(oembed[:href]).onebox
		  end
		  (doc/"link[@type='text/json+oembed']").each do |oembed|
		    return OembedOnebox.new(oembed[:href]).onebox
		  end
		end

		# 从opengraph中取onebox
		open_graph = Oneboxer.parse_open_graph(doc)
		return OpenGraphOnebox.new(url, open_graph).onebox if open_graph.present?
	      end
	    end
	    nil
	rescue OpenURI::HTTPError
	    nil
	end

	# 缓存版本的获取onebox，或者是删除指定已经缓存的onebox
	def self.get_onebox(url, args={})
		if args[:invalidate_oneboxes].present?
			# 删除onebox的cache内容
			delete_cache(url)
		else
			cached = render_from_cache(url, args) unless args[:no_cache].present?
			return cached.cooked if cached.present?
		end

		cooked, preview = onebox_nocache(url)
		return nil if cooked.blank?

		render_save_cache(url, cooked)

		cooked
	end

	# 对于给定的HTML内容，解释出全部的URL连接，并逐一抛出分析
	def self.each_onebox_link(string_or_doc)
		doc = string_or_doc
		doc = Nokogiri::HTML(doc) if doc.is_a?(String)

		onebox_links = doc.search("a")
		return doc unless onebox_links.present?

		onebox_links.each do |link|
			if link['href'].present?
				yield link['href'], link
			end
		end
		doc
	end

	# 传入html内容，返回经过转换onebox的html内容
	def self.map_onebox(post, args)
		doc = each_onebox_link(post) do |url, element|
			onebox = get_onebox(url, args)
			element.swap(onebox) if onebox
		end

		return doc.to_s if doc.present?
		post
	end
end
