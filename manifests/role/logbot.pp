import "../bots.pp"


#  Install the logbot for wikimedia-labs.  It logs to a page on labsconsole.
class role::logbot::wikimedia-labs {

	include passwords::misc::scripts

	class { "bots::logbot":
		ensure => latest,
		targets => ["#wikimedia-labs"],
		nick => "labs-morebots",
		wiki_connection => '("https","labsconsole.wikimedia.org")',
		wiki_path => "/w/",
		password_include_file => 'adminbotpass',
		author_map => '{ "TimStarling": "Tim", "_mary_kate_": "river", "yksinaisyyteni": "river", "flyingparchment": "river", "RobH": "RobH", "werdnum": "Andrew", "werdna": "Andrew", "werdnus": "Andrew", "aZaFred": "Fred", "^demon": "Chad" }',
		title_map => '{ "Andrew": "junior", "RoanKattouw": "Mr. Obvious", "RobH": "RobH", "notpeter": "and now dispaching a T1000 to your position to terminate you.", "domas": "o lord of the trolls, my master, my love. I can\'t live with out you; oh please log to me some more!", "^demon" : "you sysadmin wannabe.", "andrewbogott": "dummy" }',
		wiki_domain => "labs",
		wiki_page => "Nova_Resource:%s/SAL",
		wiki_header_depth => 3,
		wiki_category => "SAL";
	}
}
