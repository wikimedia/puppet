# Sets up a mongodb master
class toollabs::mongo::master inherits toollabs {
    include toollabs::infrastructure

   mongodb { "mongo":
   }
}
