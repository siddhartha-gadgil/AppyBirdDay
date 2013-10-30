package models
import play.api.libs.json._
import play.api.libs.json.Json._
import play.api.libs.functional.syntax._
import scala.annotation._

object Attributes{
    case class AttrID(typ: String, group: String = "", name: String){
			override def toString = typ+":"+group+":"+name

			def toJson: JsValue = Json.obj(
	                        "type" -> Json.toJson(typ),
	                        "group" -> Json.toJson(group),
	                        "name" -> Json.toJson(name))

			val base: AttrBase = typ match {
					case "bin" => BinAttr(this)
					case "beh" => BehavAttr(this)
					case _ => StringObj
				}
		}

	object AttrID{
		def apply(str: String): AttrID = AttrID(str.split(':')(0), str.split(':')(1), str.split(':')(2))

		def fromJson(json: JsValue): AttrID = AttrID(
	        (json \ "type").as[String], 
	        (json \ "group").as[String],
	        (json \ "name").as[String]) 

			}
    
	implicit object AttrFormat extends Format[AttrID]{
	    def reads(json: JsValue) = JsSuccess(AttrID(
	        (json \ "type").as[String], 
	        (json \ "group").as[String],
	        (json \ "name").as[String]))
	        
	    def writes(a: AttrID): JsValue = Json.obj(
	                        "type" -> toJson(a.typ),
	                        "group" -> toJson(a.group),
	                        "name" -> toJson(a.name))
	      }
			
	trait FromString[A]{
		def fromString(s: String): A
		

			}	

	def fromString[A](s: String)(implicit conv: FromString[A]): A = conv.fromString(s)	

	implicit object StringItself extends FromString[String]{
		def fromString(s: String) = s
		} 

    trait AttrBase{
		
        type descType  
        type repType
        
				def descFromJson(js: JsValue): descType

				def repFromJson(js: JsValue): repType

				def descToJson(desc: descType): JsValue

				def repToJson(rep: repType): JsValue
				
				def repFromString(rep: String): repType 
				
				def descFromString(rep: String): descType

        val repDefault: repType
  
    }

		trait Attr extends AttrBase{
			  def diff(desc: descType, rep: repType): Int
        
			  def diffAny(d: Any, r: Any) : Int = diff(d.asInstanceOf[descType], r.asInstanceOf[repType])

			  val choices: List[String]
			  
			  val id: AttrID
		}
		
    	case class  StrLookup(m: AttrID => StringAttr){
			def apply(attrID: AttrID): StringAttr = m(attrID)
			}

		object Attr{
			def apply(typID: String)(implicit s: StrLookup): Attr = apply(AttrID(typID))

			def apply(attrID: AttrID)(implicit s: StrLookup): Attr = attrID match {
					case AttrID("beh", group, id) => BehavAttr(attrID)
					case AttrID("bin", group, id) => BinAttr(attrID)
					case AttrID( _ , group, id) => s(attrID)
				}
    }

    
    class Visibility
    case object Prominent extends Visibility    
    case object Present extends Visibility    
    case object Absent extends Visibility
    
    object Visibility{
        val fromString = Map("Prominent" -> Prominent,
                            "Present" -> Present,
                            "Absent" -> Absent)
        

                    
        def toJson(v: Visibility) = Json.toJson(v.toString)
        
        def fromJson(js: JsValue): Visibility = fromString(js.as[String])

        }
    
		implicit object VisibString extends FromString[Visibility]{
			def fromString(s: String) = Visibility.fromString(s)
			} 
    
    trait BinAttrBase extends Attr{
        type descType = Visibility
        type repType = Boolean
        
        val repDefault = false
        
        def diff(desc: Visibility, rep: Boolean) = (desc, rep) match {
            case (Prominent, false) => 5
            case (Present, false) => 1
            case (Absent, true) => 5
            case  _ => 0
				}
  
				def descFromJson(js: JsValue) = Visibility.fromJson(js)

				def repFromJson(js: JsValue) = js.as[Boolean]
      
				def descToJson(desc: Visibility): JsValue = Json.toJson(desc.toString)

				def repToJson(rep: Boolean): JsValue = Json.toJson(rep)

				val choices = Visibility.fromString.keys.toList
				
				def descFromString(s: String) = Visibility.fromString(s)
				
				def repFromString(rep: String) = if (rep.toLowerCase == "seen") true else false
    }    

    case class BinAttr(id: AttrID) extends BinAttrBase{
				override def toString = id.toString
			}
        
    object BinAttr{
        def apply(group: String ="", name: String): BinAttr = BinAttr(AttrID("bin", group, name))
    }
    
    class Behaviour 
    case object Usually extends Behaviour
    case object Sometimes extends Behaviour
    case object Rarely extends Behaviour
    case object Never extends Behaviour
    
    
    trait BehavAttrBase extends Attr{
        type descType = Behaviour
        type repType = Boolean
        
        val repDefault = false
        
        def diff(desc: Behaviour, rep: Boolean) = (desc, rep) match {
            case (Usually, false) => 3
            case (Usually, true) => -5
            case (Sometimes, true) => -2
            case (Rarely, true) => 3
            case (Never, true) => 7
            case _ => 0
        }

				def descFromJson(js: JsValue) = Behaviour.fromJson(js)

				def repFromJson(js: JsValue) = js.as[Boolean]

				def descToJson(desc: Behaviour): JsValue = Json.toJson(desc.toString)

				def repToJson(rep: Boolean): JsValue = Json.toJson(rep)	
				
				def descFromString(s: String) = Behaviour.fromString(s)
				
				def repFromString(rep: String) = if (rep.toLowerCase == "seen") true else false

				val choices = Behaviour.fromString.keys.toList
    }   
    
    object Behaviour{
        val fromString = Map("Usually" -> Usually,
                            "Sometimes" -> Sometimes,
                            "Rarely" -> Rarely,
                            "Never" -> Never)
                            
        def toJson(b: Behaviour) = Json.toJson(b.toString)
        
        def fromJson(js: JsValue) = fromString(js.as[String])
        }

		implicit object BehavString extends FromString[Behaviour]{
			def fromString(s: String) = Behaviour.fromString(s)
			} 

    case class BehavAttr(id: AttrID) extends BehavAttrBase{
			override def toString = id.toString
		}    

    
    object BehavAttr{
        def apply(group: String ="", name: String): BehavAttr = BehavAttr(AttrID("beh", group, name))

    }

    def stringDiff(n: Int): (String, String) => Int ={
        case (a: String, "") => 0
        case (a: String, b: String) => if (a == b) -n else n 
    }

    def mapDiff(m: Map[(String, String), Int], n: Int) : (String, String) => Int ={
        (a: String, b: String) => m.getOrElse((a, b), stringDiff(n)(a, b))
    }
    
		trait StringAttrBase extends AttrBase{
        type descType = String
        type repType = String
        val repDefault = ""

				def descFromJson(js: JsValue) = js.as[String]

				def repFromJson(js: JsValue) = js.as[String]

				def descToJson(desc: String): JsValue = Json.toJson(desc)

				def repToJson(rep: String): JsValue = Json.toJson(rep)

				def descFromString(desc: String) = desc
				
				def repFromString(rep: String) = rep
			}

		case object StringObj extends StringAttrBase

		class StringClass(choices: List[String], diffFn: (String, String)=> Int){
				def apply(id: AttrID) = StringAttr(id, choices, diffFn)
				}
   
    case class StringAttr(id: AttrID, choices: List[String], 
        diffFn: (String, String) => Int) extends StringClass(choices, diffFn) with StringAttrBase with Attr{

        
        def diff(a: String, b: String) = if (b == "") 0 else diffFn(a,b)
        def ++(ch: List[String]) = StringAttr(id, choices ++ ch, diffFn)
        def clone(cloneID: AttrID) = StringAttr(cloneID, choices, diffFn)
        def clone(group: String = "", name: String) = StringAttr(
                                        AttrID("str", group, name), choices, diffFn)

				def datumList = for(desc<- choices; rep <-choices) yield StringDistDatum(desc, rep, diff(desc, rep))
				def data = StringAttrData(id, choices, datumList)

				override def toString = id.toString
    }

		val defaultFn: ((String, String)) => Int = (xy:(String, String)) => stringDiff(5)(xy._1,xy._2)

		def OrFive(m: Map[(String, String), Int]): (String, String) => Int = (x: String, y: String) => {
				(m orElse flip(m)) applyOrElse ((x,y), defaultFn)
				}
			

		object StringAttr{
			def apply(group: String ="", name: String, choices: List[String], 
								dfMap: Map[(String, String), Int] = Map.empty): StringAttr = StringAttr(AttrID("str", group, name),
															choices, (a: String, b: String) => dfMap getOrElse((a,b), stringDiff(5)(a, b))) 
			}    

		def flip(m: Map[(String, String), Int]) = (for (((x,y), z) <-m) yield ((y,x), z)).toMap 

		def posDiff[A](l: List[A], wt: Int = 2) : Map[(A, A), Int] = {
		    (for (i<-0 to l.length; j <-0 to l.length) yield ((l(i), l(j)), (i-j)*(i-j)*wt)).toMap
		}
		
		case class StringDistDatum(desc: String, rep: String, dist: Int){
			def toJson = Json.obj("desc" -> Json.toJson(desc), "rep" -> Json.toJson(rep), "dist" -> Json.toJson(dist))
			}
		
		object StringDistDatum{
			def fromJson(js: JsValue) = StringDistDatum((js \ "desc").as[String], 
																									(js \ "rep").as[String], 
																									(js \ "dist").as[Int])
		}

		case class StringAttrData(id: AttrID, choices: List[String], distances: List[StringDistDatum]){
			def toJson = Json.obj("id" -> id.toJson,
													"choices" -> Json.toJson(choices), 
													"distances" -> Json.toJson(distances map (_.toJson)))

			def diffMap : Map[(String, String), Int] = {
					(for (StringDistDatum(desc, rep, dist)<- distances) yield 
						((desc.asInstanceOf[String], rep.asInstanceOf[String]) -> dist.asInstanceOf[Int])).toMap  
			}

			def diffFn: (String, String) => Int = (d, r) => diffMap((d,r))

			def attr = StringAttr(id, choices, diffFn)
		}

		object StringAttrData{
			def fromJson(js: JsValue) = StringAttrData((js \"id").as[AttrID],
																									(js \ "choices").as[List[String]],
																								 (js \ "distances").as[List[JsValue]] map (StringDistDatum.fromJson(_)))
			}

  
    case class Rep(rep: Map[AttrID, Any]){
        def apply(attrID: AttrID) = rep.getOrElse(attrID, attrID.base.repDefault)
        
        def apply(attr: Attr) = rep.getOrElse(attr.id, attr.id.base.repDefault)

				def ++(m: Map[AttrID, Any]) = Rep(rep ++ m)

				lazy val jsonMap = (for ((attrID, value) <- rep) yield 
						(attrID.toString, attrID.base.descToJson(value.asInstanceOf[attrID.base.descType]))).toMap  

				def toJson = Json.toJson(jsonMap)
    }

		object Rep{
			def fromJson(js: JsValue): Rep = {
				val strMap = js.as[Map[String, JsValue]]
				val repMap: Map[AttrID, Any] = (for ((a, j) <- strMap) yield 
								(AttrID(a), AttrID(a).base.repFromJson(j))).toMap
				Rep(repMap)
				}
			
			def fromQuery(m: Map[String, Seq[String]])(implicit s: StrLookup) ={
			  Rep((for ((x, l)<-m; z<- l.headOption) yield (AttrID(x), Attr.apply(x)(s).repFromString(z))).toMap) 
			}
		}
    
    case class Desc(desc: Map[AttrID, Any]){
        def score(rep: Rep)(implicit s: StrLookup) = {
            for ((attrID, value) <- desc) yield (attrID, Attr(attrID).diffAny(value, rep(attrID)))
        }
				
				def ++(m: Map[AttrID, Any]) = Desc(desc ++ m)

				lazy val jsonMap = (for ((attrID, value) <- desc) yield 
						(attrID.toString, attrID.base.repToJson(value.asInstanceOf[attrID.base.repType]))).toMap  

				def toJson = Json.toJson(jsonMap)

				def weightedScore(rep: Rep, wts: WeightSystem = WeightSystem.empty)(implicit s: StrLookup) = {
					(for ((attrID, sc) <- score(rep)) yield (sc * wts.weights.getOrElse(attrID, 1))).sum
					}

    }

		object Desc{
			def fromJson(js: JsValue): Desc = {
				val strMap = js.as[Map[String, JsValue]]
				val descMap: Map[AttrID, Any] = (for ((a, j) <- strMap) yield (AttrID(a), AttrID(a).base.descFromJson(j))).toMap
				Desc(descMap)
				}
			
			def fromQuery(m: Map[String, Seq[String]])(implicit s: StrLookup) ={
			  Desc((for ((x, l)<-m; z<- l.headOption) yield (AttrID(x), Attr.apply(x)(s).descFromString(z))).toMap) 
			}

		}  

		case class WeightSystem(ref: String, weights: Map[AttrID, Int]){
				val strMap = (for((a,n) <- weights) yield (a.toString, n)).toMap  
				def toJson = Json.obj("ref" -> Json.toJson(ref), "weights" -> Json.toJson(strMap))
		}

		object WeightSystem{
			def fromJson(js: JsValue) = {
				val jsMap = (js \ "weights").as[Map[String, Int]]
				WeightSystem((js \ "ref").as[String], (for ((str, n) <- jsMap) yield (AttrID(str), n)).toMap)
			}	

			val empty = WeightSystem("", Map.empty)	
		}

		case class AbundanceData(ref: String, abundance: Map[String, Int]){
		    def apply(sci: String) = abundance.getOrElse(sci, 0)
		    
			def toJson = Json.obj( "ref" -> Json.toJson(ref),																		
														"abundance" -> Json.toJson(abundance))
			}

		object AbundanceData{
			def fromJson(js: JsValue) = AbundanceData((js \ "ref").as[String], 
																								(js \ "abundance").as[Map[String, Int]]
																							)  
			val empty = AbundanceData("", Map.empty)
		}

		 

		case class SpeciesDesc(name: String, scientific: String, url: String, desc: Desc){
			def entropy(rep: Rep, abnd: AbundanceData = AbundanceData.empty, 
								wts: WeightSystem = WeightSystem.empty )(implicit s: StrLookup) = {
					desc.weightedScore(rep, wts) - abnd.abundance.getOrElse(scientific, 0)
				}

			def toJson = Json.obj( "name" -> Json.toJson(name),
								"scientific" -> Json.toJson(scientific),
								"url" -> Json.toJson(url),
								"desc" -> desc.toJson)
		}

		object SpeciesDesc{
			def fromJson(js: JsValue) = SpeciesDesc((js \ "name").as[String], 
																								(js \ "scientific").as[String],
																								(js \ "url").as[String],
																								Desc.fromJson(js)
																							)
						
			@tailrec def best(n: Int)(species: List[SpeciesDesc], soFar: List[SpeciesDesc]=List.empty, rep: Rep, abnd: AbundanceData = AbundanceData.empty, 
								wts: WeightSystem = WeightSystem.empty )(implicit s: StrLookup): List[SpeciesDesc] = {
								if (n<=soFar.length) soFar take n else best(n)(species, soFar :+(species maxBy (_.entropy(rep, abnd, wts)(s))), rep, abnd, wts)(s)}
		}


		implicit object SpeciesFormat extends Format[SpeciesDesc]{
			def reads(js: JsValue) = JsSuccess(SpeciesDesc.fromJson(js))

			def writes(desc: SpeciesDesc): JsValue = desc.toJson
			}
		

		implicit object StringAttrDataFormat extends Format[StringAttrData]{
			def reads(js: JsValue) = JsSuccess(StringAttrData.fromJson(js))

			def writes(strData: StringAttrData): JsValue = strData.toJson
			}

		implicit object WeightSystemFormat extends Format[WeightSystem]{
			def reads(js: JsValue) = JsSuccess(WeightSystem.fromJson(js))

			def writes(ws: WeightSystem): JsValue = ws.toJson
			}

		implicit object AbundanceDataFormat extends Format[AbundanceData]{
			def reads(js: JsValue) = JsSuccess(AbundanceData.fromJson(js))

			def writes(data: AbundanceData): JsValue = data.toJson
			}

	
        def checked(b: Boolean) = if (b) "checked" else ""			
// Collections: SpeciesDesc, AttrIDs, StringAttrData, WeightSystem, AbundanceData 
}




