require 'tempfile'
require 'open3'
require 'json'
PARSER = '~/.pyenv/versions/3.10.11/bin/gtfs-parser'
JSONS_PATH = 'a.jsons'
MINZOOM = {
  'aggregated_routes' => 8,
  'aggregated_stops' => 1,
  'routes' => 12,
  'stops' => 10 
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
    'minzoom' => MINZOOM[t]
  }
  $stderr.print "[#{$count}]\r"
  $w.print "#{JSON.dump(f)}\n"
end

def process(url)
  Dir.mktmpdir {|dir|
    gtfs_path = "#{dir}/gtfs.zip"
    geojson_path = "#{dir}/geojson"
    command("curl --silent -o #{gtfs_path} #{url}")
    command("#{PARSER} parse #{gtfs_path} #{geojson_path}")
    command("#{PARSER} aggregate #{gtfs_path} #{geojson_path}")
    %w{routes aggregated_routes stops aggregated_stops}.each {|t|
      IO.popen("tippecanoe-json-tool #{geojson_path}/#{t}.geojson") {|io|
        io.each_line {|l|
          feature(JSON.parse(l), t)
        }
        $stderr.print "[#{$count}] by #{t}\n"
      } 
    }
  }
end

$w = File.open(JSONS_PATH, 'w')
while gets
  process($_.strip.gsub(/^"|"$/, ''))
end
$w.close
