require 'time'
data = {}
indexes = {}
HOUR = 60 * 60
MIN_DEAL_COUNT = 1
def is_number?(obj)
    obj.to_s == obj.to_i.to_s
end
def usage
    """
    usage: 
        ruby #{__FILE__} <path to export csv>
            default export file name is the latest csv file starts with 'export' in file name in directory: #{File.expand_path(File.dirname(__FILE__))} 
    """
end
file = ''
if ARGV.empty?
    csv = Dir.glob("export*csv").max_by {|f| File.mtime(f)}
    file = csv if csv
else
    file = ARGV.first unless ARGV.empty? 
end

unless File.exist?(file)
    puts "File not found #{file}"
    puts usage
    exit 1
end
File.readlines(file).each do |line|
    items = line.split(';')
    unless is_number?(items.first)
        # build the index
        items.each_with_index {|value, index| indexes[value] = index }
        next
    end
    bot = items[indexes["bot"]]
    pair = items[indexes["pair"]]
    profit_percentage_from_total_volume = items[indexes["profit_percentage_from_total_volume"]]
    final_profit = items[indexes["final_profit"]]
    closed_at = items[indexes["closed_at"]]
    name = "#{bot} - #{pair}"
    if data[name]
        data[name] << {pair: pair, profit_percentage_from_total_volume: profit_percentage_from_total_volume.to_f, final_profit: final_profit.to_f, closed_at: Time.parse(closed_at)}
    else
        data[name] = [{pair: pair, profit_percentage_from_total_volume: profit_percentage_from_total_volume.to_f, final_profit: final_profit.to_f, closed_at: Time.parse(closed_at)}]
    end
end
now = Time.now
header = "name, deal_count, total_profit_percentage_from_total_volume, total_final_profit"

def print_stat(data, now, hours, comment)
    puts "#{'='*12} #{comment} #{'='*12} "
    puts "name, deal_count, total_profit_percentage_from_total_volume, total_final_profit"
    data.inject({}) { |h, (k, v)| h[k] = v.reject{|hash| now - hours*HOUR >= hash[:closed_at] }; h }.sort_by{|k, v| v.size}.each do |name, d| 
        next if d.size <= MIN_DEAL_COUNT
        total_profit_percentage_from_total_volume = d.inject(0.0) {|sum, hash| sum + hash[:profit_percentage_from_total_volume]}
        total_final_profit = d.inject(0) {|sum, hash| sum + hash[:final_profit]}
        puts "#{name}, #{d.size}, #{total_profit_percentage_from_total_volume.round(3)}, #{total_final_profit.round(3)}" 
    end
end

print_stat(data,now,99999, "all time")
print_stat(data,now,24 * 7 * 30, "last 30 days")
print_stat(data,now,24 * 7, "last 7 days")
print_stat(data,now,24, "last 24 hours")
print_stat(data,now,12, "last 12 hours")
print_stat(data,now,6, "last 6 hours")
puts "file processed: #{file}"