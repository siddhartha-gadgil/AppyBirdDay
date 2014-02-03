package models

import play.api._

import play.api.mvc._

import scala.concurrent.Await
import akka.pattern.ask
import akka.util.Timeout
import scala.concurrent.duration._
import scala.language.postfixOps
import scala.concurrent.Future

// Reactive Mongo imports
import reactivemongo.api._

// Reactive Mongo plugin
import play.modules.reactivemongo._
import play.modules.reactivemongo.json.collection.JSONCollection

// Play Json imports
import play.api.libs.json._

import play.api.Play.current

import play.api.libs.iteratee._
import play.api.libs.EventSource


import models.Attributes._

object DataStore extends Controller with MongoController {

	val all: JsObject = new JsObject(Seq.empty)	
  

	def attrIDColl: JSONCollection = db.collection[JSONCollection]("AttributeIDList")

	def attrIDList = attrIDColl.find(all).cursor[AttrID].toList

//	def behavIDList = attrIDColl.find(Json.obj("typ" -> "beh")).cursor[AttrID].toList
		
	def binAttrIDList = attrIDColl.find(Json.obj("typ" -> "bin")).cursor[AttrID].toList

	def strAttrIDList = attrIDColl.find(Json.obj("typ" -> "str")).cursor[AttrID].toList

	def insertAttrID(attr: AttrID) = attrIDColl.insert(attr)	


	
	def speciesDescColl: JSONCollection = db.collection[JSONCollection]("SpeciesDescription")

	def speciesDescList = speciesDescColl.find(all).cursor[SpeciesDesc].toList
	
	def insertSpecies(desc: SpeciesDesc) = speciesDescColl.insert(desc)
	

	def stringAttrDataColl: JSONCollection = db.collection[JSONCollection]("StringAttributesData")

	def stringAttrDataList = stringAttrDataColl.find(all).cursor[StringAttrData].toList

	def StringAttrFut(id: AttrID) = stringAttrDataColl.find(Json.obj("id" ->id.toJson)).
																	cursor[StringAttrData].
																	headOption map (_.get.attr)
	implicit val timeout = Timeout(25 seconds) 
	
	def StringAttrNow(id: AttrID) = Await.result(StringAttrFut(id), timeout.duration)
	
//	implicit val strLookUp = StrLookup(StringAttrNow)

	def weightSystemColl: JSONCollection = db.collection[JSONCollection]("WeightSystem")

	def weightSystemList = weightSystemColl.find(all).cursor[WeightSystem].toList
	
	def weightMap(ref: String) = weightSystemColl.find(Json.obj("ref" -> Json.toJson(ref))).
																	cursor[WeightSystem].toList.map(_.head).map(_.weights)
	

	def abundanceDataColl: JSONCollection = db.collection[JSONCollection]("AbundanceData")

	def abundanceDataList = abundanceDataColl.find(all).cursor[AbundanceData].toList
	
	def abundanceDataNow = Await.result(abundanceDataList, timeout.duration)

//	def abundanceJsonList = Json.toJson(Await.result(abundanceDataColl.find(all).cursor[JsValue].toList, timeout.duration))

	def abundanceJsonList = abundanceDataColl.find(all).cursor[JsValue].toList map ((l: List[JsValue] ) => Json.toJson(l))
	
	def abundanceMap(ref: String) = abundanceDataColl.find(Json.obj("ref" -> Json.toJson(ref))).
																	cursor[AbundanceData].toList.map(_.head).map(_.abundance)
	
	def abundanceInsert(abDat: AbundanceData) = abundanceDataColl.insert(abDat)
																	
	val brdRace = models.BirdRace.Bangalore2011.upload
	
	
	def wikiDataColl: JSONCollection = db.collection[JSONCollection]("WikiData")
	
	def wikiDataBirds = wikiDataColl.find(all).cursor[JsObject].toList.map (Json.toJson(_))
	
	def WikiFut = Future({println(WikiRead.birdsJson); WikiRead.birdsJson})
	
	def wikiUpload = WikiFut flatMap ((birds: List[JsObject]) => 
	  			Future.sequence(birds.map((bird: JsObject) => wikiDataColl.insert(bird))))
  
	def birdDescColl: JSONCollection = db.collection[JSONCollection]("BirdDescriptions")	

    def addDesc(desc: JsObject) = {
	  birdDescColl.find(desc).cursor[JsObject].toList.map{(l)=>  
	    if (l.isEmpty) birdDescColl.insert(desc)}
//	  birdDescColl.insert(desc)	
	}
	
	def saveDesc(desc: JsObject) = { 
	  birdDescColl.save(desc)
	  channel.push(desc)
	  println("boing")
	}
	
	def removDesc(id: JsObject) = birdDescColl.remove(id)
	
    def birdDescs = birdDescColl.find(all).cursor[JsObject].toList.map(Json.toJson(_))
    
    val (boingout, channel) = Concurrent.broadcast[JsValue]
}

