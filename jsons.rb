require 'tempfile'
require 'open3'
require 'json'
PARSER = '~/.pyenv/versions/3.10.11/bin/gtfs-parser'
JSONS_PATH = 'a.jsons'
MINZOOMS = {
  'aggregated_routes' => 8,
  'aggregated_stops' => 1,
  'routes' => 12,
  'stops' => 12 
}
MAXZOOMS = {
  'aggregated_routes' => 11,
  'aggregated_stops' => 11,
  'routes' => 14,
  'stops' => 14
}

$count = 0

def command(cmd)
  print cmd, "\n"
  system cmd
end

def feature(f, t)
  $count += 1
  f['tippecanoe'] = {
    'layer' => t,
    'minzoom' => MINZOOMS[t],
    'maxzoom' => MAXZOOMS[t]
  }
  $stderr.print "[#{$count}]\r"
  $w.print "#{JSON.dump(f)}\n"
end

def process(url)
  Dir.mktmpdir {|dir|
    gtfs_path = "#{dir}/gtfs.zip"
    parse_dir = "#{dir}/parse"
    aggregate_dir = "#{dir}/aggregate"
    command("curl --silent -o #{gtfs_path} #{url}")
    command("#{PARSER} parse #{gtfs_path} #{parse_dir}")
    command("#{PARSER} aggregate #{gtfs_path} #{aggregate_dir}")
    %w{routes aggregated_routes stops aggregated_stops}.each {|t|
    #%w{routes stops}.each {|t|
      src_dir = /aggregated/.match(t) ? aggregate_dir : parse_dir
      src_path = "#{src_dir}/#{t}.geojson"
      IO.popen("tippecanoe-json-tool #{src_path}") {|io|
        io.each_line {|l|
          feature(JSON.parse(l), t)
        }
        $stderr.print "[#{$count}] by #{t}\n"
      } if File.exist?(src_path) 
    }
  }
end

file_count = 0
$w = File.open(JSONS_PATH, 'w')
while gets
  file_count += 1
  $stderr.print "URL ##{file_count}\n"
  process($_.strip.gsub(/^"|"$/, ''))
end
$w.close
