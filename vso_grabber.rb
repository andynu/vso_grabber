#!/usr/bin/env ruby
require 'mechanize'
require 'chronic'

# Generates curl commands for downloading sun images in various spectral ranges
# by default it gives you the first image in each band for the first day of each month
# in the provided <year> (defaults to 2013)
#
# ./sun_grabber.rb <year>

class VsoGrabber
  def initialize
    @agent = Mechanize.new
    @agent.user_agent_alias = 'Mac Safari'
  end

  def get(start_date=nil, end_date=nil, frequencies=nil)
    start_date ||= Chronic.parse('2012-01-01')
    end_date ||= start_date + 60
    frequencies ||= [94,335,193,131,171,211]

    # Form 1
    search_url = "http://sdac.virtualsolar.org/cgi/search"
    page = @agent.get search_url
    search_form = page.form_with :action => "/cgi/search"
    search_form.checkboxes[1].check # insturment checkbox

    # Form 2
    # http://sdac.virtualsolar.org/cgi/search?time=1&instrument=1&version=current&build=1
    page = @agent.submit search_form
    search_form = page.form_with :action => "http://sdac.virtualsolar.org/cgi/vsoui"
    search_form.checkboxes.each do |chk|
      if chk.value == "JSOC.SDO.AIA"
        chk.check
      end
    end

    search_form.field_with(:name => "startyear").value = start_date.strftime("%Y")
    search_form.field_with(:name => "startmonth").value = start_date.strftime("%H")
    search_form.field_with(:name => "startday").value = start_date.strftime("%d")
    search_form.field_with(:name => "starthour").value = "00"
    search_form.field_with(:name => "startminute").value = "00"

    search_form.field_with(:name => "endyear").value = end_date.strftime("%Y")
    search_form.field_with(:name => "endmonth").value = end_date.strftime("%H")
    search_form.field_with(:name => "endday").value = end_date.strftime("%d")
    search_form.field_with(:name => "endhour").value = "00"
    search_form.field_with(:name => "endminute").value = "01"
    
    # Skip ahead? Use the real API? Maybe later.
    # http://sdac.virtualsolar.org/cgi/vsoui
    #  startyear:2013
    #  startmonth:02
    #  startday:07
    #  starthour:00
    #  startminute:00
    #  endyear:2013
    #  endmonth:02
    #  endday:07
    #  endhour:00
    #  endminute:01
    #  instrument:JSOC.SDO.AIA

    # Form 3
    page = @agent.submit search_form
    search_form = page.form_with :action => "/cgi/vsoui"

    first_frequencies = frequencies.dup
    page.parser.css("#tableBody tr").each do |tr|
      node = tr.css("[name=data]").first
      unless node.nil?
        chk = Mechanize::Form::CheckBox.new(node, search_form)
        freq = tr.css("[name=__waveminu]").text.to_i
        if first_frequencies.include? freq
          chk.checked = true
          first_frequencies.delete freq # so we only grab the first one
        else
          chk.checked = false
        end
      end
    end

    # Form 4
    page = search_form.submit search_form.button_with(:name => 'requestdata')
    search_form = page.form_with :action => "/cgi/cartui"

    # Results!
    page = search_form.submit search_form.button_with(:name => 'cartFireRequest')
    first_frequencies = frequencies.dup
    page.parser.css(".col-B a").each do |link|
      href = link[:href]
      first_frequencies.each do |freq|
        if href =~ /record=(\d+)/ 
          if $1 == freq.to_s
            
            # e.g. 2013-01-01.94.fits
            filename = "#{start_date.strftime("%Y-%m-%d.#{freq}.fits")}"

            # The command to download the files
            puts "curl --progress-bar -o #{filename} \"#{href}\""

            first_frequencies.delete freq # don't repeat ourselves
          end
        end
      end
    end
  end
end

if $0 == __FILE__
  year = ARGV[0] || "2013"
  1.upto(12) do |m|
    month = "%02d" % [m]
    puts "# #{month}"
    VsoGrabber.new.get(Chronic.parse("#{year}-#{month}-01"))
  end
end
