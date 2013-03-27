##########################################################################
# Copyright 2009 Applied Research in Patacriticism and the University of Virginia
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################

namespace :solr do

	desc "Start the solr java app (Prerequisite for running)"
	task :start  => :environment do
		puts "~~~~~~~~~~~ Starting solr..."
		`cd #{SOLR_PATH} && java -Djetty.port=8983 -DSTOP.PORT=8078 -DSTOP.KEY=mustard -Xmx800m -jar start.jar &`
	end
	
	desc "Stop the solr java app"
	task :stop  => :environment do
		puts "~~~~~~~~~~~ Stopping solr..."
		`cd #{SOLR_PATH} && java -Djetty.port=8983 -DSTOP.PORT=8078 -DSTOP.KEY=mustard -jar start.jar --stop`
		puts "Finished."
	end

	desc "Restart solr"
	task :restart => :environment do
		Rake::Task['solr:stop'].invoke
		Rake::Task['solr:start'].invoke
	end
end

