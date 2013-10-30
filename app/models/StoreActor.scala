package models

import akka.actor._
import scala.concurrent.duration._

import play.api._
import play.api.libs.json._
import play.api.libs.iteratee._
import play.api.libs.concurrent._

import akka.util.Timeout
import akka.pattern.ask

import play.api.Play.current
import play.api.libs.concurrent.Execution.Implicits._



object StoreActor{

	case object IncTest 

	class IncActor extends Actor{

		var store: Int = 0

		def receive = {
			case IncTest => 
				store = store + 1
				println(store)
				}

	}

	val IncStore = Akka.system.actorOf(Props[IncActor])

	}
