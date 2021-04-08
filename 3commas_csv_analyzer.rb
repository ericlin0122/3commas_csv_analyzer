require 'time'
require 'colorize'
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
    status = items[indexes["status"]]
    next unless status =~ /completed/i
    bot = items[indexes["bot"]]
    next if bot == "complex bot - btc strong buy"
    pair = items[indexes["pair"]]
    profit_percentage_from_total_volume = items[indexes["profit_percentage_from_total_volume"]]
    final_profit = items[indexes["final_profit"]]
    closed_at = items[indexes["closed_at"]]
    used_safety_orders = items[indexes["used_safety_orders"]].to_i
    bot_type = items[indexes["bot_pairs"]].to_i > 1 ? "complex" : "simple"
    name = "#{bot} - #{pair}"
    if data[name]
        data[name] << {pair: pair, profit_percentage_from_total_volume: profit_percentage_from_total_volume.to_f, final_profit: final_profit.to_f, closed_at: Time.parse(closed_at), used_safety_orders: used_safety_orders, bot_type: bot_type}
    else
        data[name] = [{pair: pair, profit_percentage_from_total_volume: profit_percentage_from_total_volume.to_f, final_profit: final_profit.to_f, closed_at: Time.parse(closed_at), used_safety_orders: used_safety_orders, bot_type: bot_type}]
    end
end
now = Time.now
header = "name, deal_count, total_profit_percentage_from_total_volume, total_final_profit"

def print_stat(data, now, hours, comment)
    puts "#{'='*12} #{comment} #{'='*12} "
    puts "name, deal_count, total_profit_percentage_from_total_volume(%), total_final_profit($), total_used_safety_orders(average per trade)"
    i = 1
    complex = {pairs: 0, deal_count: 0, profit_in_dollar: 0.0, profit_in_percent: 0.0, safety_orders: 0}
    simple = {pairs: 0, deal_count: 0, profit_in_dollar: 0.0, profit_in_percent: 0.0, safety_orders: 0}
    data.inject({}) { |h, (k, v)| h[k] = v.reject{|hash| now - hours*HOUR >= hash[:closed_at] }; h }.sort_by{|k, v| v.size}.reverse.each do |name, d| 
        next if d.size <= MIN_DEAL_COUNT
        total_profit_percentage_from_total_volume = d.inject(0.0) {|sum, hash| sum + hash[:profit_percentage_from_total_volume]}
        total_used_safety_orders = d.inject(0) {|sum, hash| sum + hash[:used_safety_orders]}
        total_final_profit = d.inject(0) {|sum, hash| sum + hash[:final_profit]}
        bot_type = d.first[:bot_type] 
        if bot_type == 'simple'
            simple[:pairs] += 1
            simple[:deal_count] += d.size
            simple[:profit_in_dollar] += total_final_profit
            simple[:profit_in_percent] += total_profit_percentage_from_total_volume
            simple[:safety_orders] += total_used_safety_orders
        else
            complex[:pairs] += 1
            complex[:deal_count] += d.size
            complex[:profit_in_dollar] += total_final_profit
            complex[:profit_in_percent] += total_profit_percentage_from_total_volume
            complex[:safety_orders] += total_used_safety_orders
        end
        ratio = (total_final_profit/d.size*1.0).round(1)
        puts "#{i} #{bot_type == 'complex' ? name.light_blue : name }, #{d.size}, #{total_profit_percentage_from_total_volume.round(3)}%, $#{total_final_profit.round(3)}, #{total_used_safety_orders}(#{ratio >= 1.0 ? "#{ratio}".red : ratio})" 
        i += 1
    end
    puts '-' * 40
    puts "simple pair stats: #{simple.inspect}"
    puts "complex pair stats: #{complex.inspect}"
    puts "combined stats: #{simple.merge(complex) { |k, o, n| o + n }}"
end

print_stat(data,now,99999, "all time")
print_stat(data,now,24 * 7 * 30, "last 30 days")
print_stat(data,now,24 * 7, "last 7 days")
print_stat(data,now,24, "last 24 hours")
print_stat(data,now,12, "last 12 hours")
print_stat(data,now,6, "last 6 hours")
print_stat(data,now,3, "last 3 hours")
puts "file processed: #{file}"