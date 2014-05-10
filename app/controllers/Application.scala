package controllers

import play.api._
import play.api.mvc._

import play.api.libs.json._
import play.api.libs.iteratee._
import play.api.libs.EventSource

import models.Attributes._
import models.WikiRead._
import models.DataStore._
//import models.StoreActor._


object Application extends Controller{
 
  val strAttList = List(StringAttr("", "size", List("sparrow", "myna", "crow")), 
                                            StringAttr("another", "size", List("sparrow", "myna", "crow")))
  def strAttfromID(id: AttrID) = (strAttList find (_.id == id)).get 
  
  implicit val strLookUp = StrLookup(strAttfromID)
  
  def query = Action { request => 
					// val queryOpt = request.body.asFormUrlEncoded
    				val query = request.queryString
    				println(query)
    				val rep = Rep.fromQuery(query)
						
//						IncStore ! IncTest

					Ok(views.html.query(List(BinAttr("tail", "forked"), BinAttr("tail", "long")).groupBy(_.id.group), 
                                        List(BehavAttr(AttrID("beh","seen","swimming")), 
                                            BehavAttr(AttrID("beh","habitat", "scrub"))).groupBy(_.id.group), 
                                        strAttList, 
                                        bestBirds, 
                                        rep))}
  
  def getHeads(m: Map[String, Seq[String]]): Map[String, String] = {
      (for ((x, l) <- m; h <- l.headOption) yield (x, h)).toMap
      }                  
  
  
  def descJsObj(m: Map[String, Seq[String]])  = {
      val jsList = (for ((x, s)<- m; h <- s.headOption) yield (x, Json.toJson(h))).toList
       JsObject(jsList)
  }
  
  def birdJsObj(sci: String, morph: String ="") = JsObject(List("sci" -> Json.toJson(sci), "morph" -> Json.toJson(morph)))
  
//  def formJson(implicit request: Request) = Json.toJson(getHeads(request.body.asFormUrlEncoded))
                                        
  def bestBirds = List(egBird, egBird, egBird)
  
  def index = Action{
    Redirect("/web/appybirddaydart.html")
  }
  
//  def birdRace2011Load = {abundanceInsert(brdRace); "bird race results loaded"}
  
  def birdRace2011UpLoad = TODO //Action { Ok(birdRace2011Load)}
  
  def abundanceView = Action {Async{abundanceJsonList map (Ok(_)) }}
  
  def wikiUploadAction = TODO /*Action{Async{
    wikiUpload map (_ => Ok("Uploaded wiki data"))}}
  */
  
  def wikiData = Action{Async(wikiDataBirds.map(Ok(_)))}
  
  def birdDesc = Action{Async(birdDescs.map(Ok(_)))}
  
  def birdDescUpload = Action { implicit request => 
    val descJsonOpt = request.body.asFormUrlEncoded.map(descJsObj)
    descJsonOpt.map((js) => {saveDesc(js); Ok(js)}).getOrElse(BadRequest("Incorrect fields"))
    }
  
  def birdRemove = Action{implicit request =>
      val descJsonOpt = request.body.asFormUrlEncoded.map(descJsObj)
      descJsonOpt.map((js) => {removDesc(js); Ok(js)}).getOrElse(BadRequest("Incorrect fields"))  
    }
  
        
    
  def logs = Action {
      implicit request => {         
          
          Ok.feed(boingout &> EventSource()).as("text/event-stream")
      }
      
  }

}

