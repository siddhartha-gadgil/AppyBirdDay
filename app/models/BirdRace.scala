package models

import scala.language.postfixOps
import scala.xml._
import scala.util.control.Exception._

object BirdRace{
		val xmlParser = XML.withSAXParser(new org.ccil.cowan.tagsoup.jaxp.SAXFactoryImpl().newSAXParser())
		def loadFile(filename: String) = xmlParser.loadFile(filename)

		def maybeInt(s: String) = allCatch.opt(s.toInt).getOrElse(0)
		
		object Bangalore2011{
			val data = loadFile("data/BirdRace2011.html")
			val rows = (data \\ "tr").toList drop 7
			val cols = rows map (_ \ "td"  toList)
			val abund = for (r <- cols if (r.length > 7 && (r(6).text != ""))) yield (r(6).text, 1+ 2 * maybeInt(r(7).text))
			val upload = Attributes.AbundanceData("Bangalore BirdRace 2011", abund.toMap)
			}
		}
