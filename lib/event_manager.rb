require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_homephone(homephone)
  homephone = homephone.split(//).map {|x| x[/\d+/]}.join
  if homephone.length < 10 
    return "Wrong number"
  elsif homephone.length == 11 && homephone[0] == "1" 
    homephone[0] = ''
    return homephone
  elsif homephone.length == 11 && homephone[0] != "1" 
    return "Wrong number"
  elsif homephone.length == 10
    return homephone
  elsif homephone.length > 11 
    return "Wrong number"
  end
end

def most_active_hours(times)
  h = times.each_with_object(Hash.new(0)) { |s,h| h[s] += 1 }
  peak_nbr = h.max_by(&:last).last
  hours = h.select { |_hr,nbr| nbr == peak_nbr }.keys
  puts "The most people registered at #{hours[0]} and #{hours[1]} hours of the day." 
end

def most_active_days(days)
  h = days.each_with_object(Hash.new(0)) { |s,h| h[s] += 1 }
  peak_nbr = h.max_by(&:last).last
  d = h.select { |_hr,nbr| nbr == peak_nbr }.keys
  puts "The most active day is #{d[0]}." 
end


def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

times = []
days = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  homephone = clean_homephone(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  puts homephone
  regdate = row[:regdate]
  date = DateTime.strptime(regdate,  '%m/%d/%y %H:%M')
  times.push(date.strftime('%H'))
  days.push(date.strftime('%A'))
  #form_letter = erb_template.result(binding)
  #save_thank_you_letter(id,form_letter)
end


most_active_hours(times)
most_active_days(days)
