package models
import scala.xml._
import scala.util.control.Exception._
import scala.util._

import play.api.libs.json._

import play.api.Play.current

object WikiRead{ 
    
    val baseUrl = "http://en.wikipedia.org"
    
    case class BirdPage(name: String, sci: String, url: String) 
    
    def birdPages(nodes: NodeSeq) = {
        for(node <- nodes; a <- (node \ "a"); 
        h <- a \ "@href"; sci <- node \ "i") yield BirdPage(a.text, sci.text, h.text) 
    }    

    def getBirds(url: String) = birdPages(XML.load(url) \\ "li")
 
    def infobox(node: Node) = ((node \ "@class").headOption map (_.text)) == Some("infobox biota")   
    
    def infoTable(node: Node) = (node \\ "table" filter infobox).head
     
    def birdPage(url: String) = XML.load(baseUrl+url)
    
    def birdImg(node: Node) = ((infoTable(node) \\ "img").head \"@src").head.text

	def birdImage(url:String) = Try {birdImg(birdPage(url))} getOrElse("")
    
    def birdTaxon(node: Node, taxon: String = "family") = {
        val taxa = infoTable(node) \\ "table" \\ "td" \\ "span"
        (for (taxnode <- taxa if ((taxnode \ "@class").headOption == Some(taxon))) yield (taxnode \ "a").head.text).head
    }
    
    val eg = <li><a href="/wiki/Fulvous_Whistling-Duck" title="Fulvous Whistling-Duck" class="mw-redirect">Fulvous Whistling-Duck</a> <i>Dendrocygna bicolor</i></li>
    
    val egBird = BirdPage("Fulvous Whistling-Duck", "Dendrocygna bicolor", "/wiki/Fulvous_Whistling-Duck")
    
    lazy val birdsJson = {val url = "http://en.wikipedia.org/wiki/List_of_birds_of_India"
                        val nodes = (XML.load(url) \\ "li").toList
                        for(node <- nodes;
                            a <- (node \ "a"); 
                            h <- a \ "@href"; sci <- node \ "i") yield {println(a.text); JsObject(List(
                                "name" -> JsString(a.text), 
                                "sci" -> JsString(sci.text), 
                                "url" -> JsString(h.text),
                                "img" -> JsString(birdImage(h.text))))}
    }
    
    lazy val birdsRawTest = {val url = "http://en.wikipedia.org/wiki/List_of_birds_of_India"
                        val nodes = (XML.load(url) \\ "li").take(80).toList
                        for(node <- nodes;
                            a <- (node \ "a"); 
                            h <- a \ "@href"; sci <- node \ "i") yield {println(a.text); JsObject(List(
                                "name" -> JsString(a.text), 
                                "sci" -> JsString(sci.text), 
                                "url" -> JsString(h.text),
                                "img" -> JsString(birdImage(h.text))))}
    }
    
        
    lazy val birdsJsonTest = Json.toJson(birdsRawTest)
}




