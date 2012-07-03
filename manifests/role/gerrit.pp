# manifests/role/gerrit.pp

class role::gerrit {

	system_role { "role::gerrit": description => "Gerrit installation" }

	class labs {
		system_role { "role::gerrit::production": description => "Gerrit in labs!" }

		gerrit::instance { "gerritlabs":
			ircbot => false
		}
	}


	class production {
		system_role { "role::gerrit::production": description => "Gerrit master" }

		gerrit::instance { "gerritproduction":
			ircbot => true,
			apache_ssl => true,
		}
	}

	class production::slave {
		system_role { "role::gerrit::slave": description => "Gerrit slave" }

		gerrit::instance{ "gerritproductionslave":
			slave => true,
			no_apache => true,
		}
	}

}
