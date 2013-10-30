import 'dart:html';
import 'dart:core';
import 'dart:async';
import 'dart:json' as JSON;

Map <String, Map<String,String>> rep = new Map();

Map<String, Map <String, Map<String,String>>> descs = new Map();

var mainColours = ["back","head", "breast"];

Map<String, List<String>> binAttr = {"Tail" : ["long", "forked"], 
                                     "Beak" : ["hooked", "long"]};


Map<String, List<String>> behAttr = {"Seen" : ["flying", "on the ground", "on a branch"],
                                     "Habitat" : ["dry", "forested"]
};

var otherColours=["leg", "beak", "neck"];

var size= query('#size_input');


String colourString(String col){
  int R = int.parse("0x"+col.substring(1, 3));
  int G = int.parse("0x"+col.substring(3, 5));
  int B = int.parse("0x"+col.substring(5, 7));
  return "($R, $G, $B)";
}


LIElement checkChoose(String group, String name, Map<String, Map<String, String>> features){
  LIElement item = new LIElement();
  var par = new ParagraphElement();
  par.text = name + ": ";
  var inp = new CheckboxInputElement();
  inp.onChange.listen((Event e){
        String value;
        if (inp.checked) {value = true.toString();} else {value = false.toString();}
        if (features.containsKey(group)) {features[group][name] = value;} 
        else {features[group] = new Map(); 
          features[group][name]= value;};
        repUpdate();
 
      });
  par.children.add(inp);
  item.children.add(par);
  return item;
}

LIElement colourChoose(String name, Map<String, Map<String, String>> features){
  LIElement item = new LIElement();
  var par = new ParagraphElement();
  par.text = name + ": ";
  var inp = new InputElement();
  inp
      ..type = "color"
      ..onChange.listen((Event e){
        if (features.containsKey("colour")) {features["colour"][name] = inp.value;} 
        else {features["colour"] = new Map(); 
          features["colour"][name]= inp.value;};
        repUpdate();
      });
  par.children.add(inp);
  item.children.add(par);
  return item;
}

UListElement checkList(String group, List<String> names, Map<String, Map<String, String>> features) {
  var ulist = new UListElement();
  names.forEach((String name){
      ulist.children.add(checkChoose(group, name, features));
  });
  return ulist;
}

void repUpdate(){
  query("#rep").text = rep.toString();
}

void setSize(String siz, Map<String, Map<String, String>> features){
 features["size"] = {"size" : siz};
 repUpdate();
}

StreamSubscription sizeQuery(Map<String, Map<String, String>> features){
  var sizeElem = new RangeInputElement();
    
  sizeElem.min ="1";
  sizeElem.max = "120";
  
  var subsc = sizeElem.onChange.listen((Event e){
    setSize(sizeElem.value, features);});
  
  query("#size").children = [sizeElem];
  return subsc;
}

List<Element> colourQuery(List<String> colours, Map<String, Map<String, String>> features){
  Iterable<LIElement> colourIter = colours.map((String col){
    return colourChoose(col, rep);
  });    

  return colourIter.toList();
}

  List<DivElement> attrListList(Map<String, List<String>> bingps
                                , Map<String, Map<String, String>> features){
    Iterable<DivElement> iterListList = bingps.keys.map((String group){
      DivElement div = new DivElement();
      div
      ..innerHtml = "<h3>$group:</h3>"
      ..children.add(checkList(group, binAttr[group], features));
      return div;
    }); 
    return iterListList.toList();
  }

void main() {
  
  var sizeclick = query('#size_input').onChange.listen((Event e){
    setSize(size.value, rep);});  

  sizeQuery(rep);
  

  query('#colour_list').children = colourQuery(mainColours, rep);
  
  
  binAttr.keys.forEach((String group){
    var div = new DivElement();
    div
        ..innerHtml = "<h3>$group:</h3>"
         ..children.add(checkList(group, binAttr[group], rep));
     query("#bin_attr").children.add(div);
  });
  
  
  behAttr.keys.forEach((String group){
    var div = new DivElement();
    div
      ..innerHtml = "<h3>$group:</h3>"
      ..children.add(checkList(group, behAttr[group], rep));
      query("#beh_attr").children.add(div);
  });
}

var wikiSample = JSON.parse(wikiSampleText);

var wikiSampleText = '''
[{"name":"Nicobar Scrubfowl","sci":"Megapodius nicobariensis","url":"/wiki/Nicobar_Scrubfowl","img":"//upload.wikimedia.org/wikipedia/commons/thumb/0/06/Nicobar_Megapode.svg/220px-Nicobar_Megapode.svg.png"},{"name":"Snow Partridge","sci":"Lerwa lerwa","url":"/wiki/Snow_Partridge","img":"//upload.wikimedia.org/wikipedia/commons/thumb/3/34/Lerwa_lerwa.jpg/220px-Lerwa_lerwa.jpg"},{"name":"Szecheny's Partridge","sci":"Tetraophasis szechenyii","url":"/wiki/Szecheny%27s_Partridge","img":"//upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Status_iucn3.1_LC.svg/220px-Status_iucn3.1_LC.svg.png"},{"name":"Tibetan Snowcock","sci":"Tetraogallus tibetanus","url":"/wiki/Tibetan_Snowcock","img":"//upload.wikimedia.org/wikipedia/commons/thumb/0/0d/Tetraogallus_tibetanus.jpg/220px-Tetraogallus_tibetanus.jpg"},{"name":"Himalayan Snowcock","sci":"Tetraogallus himalayensis","url":"/wiki/Himalayan_Snowcock","img":"//upload.wikimedia.org/wikipedia/commons/thumb/c/c8/Himalayan_Snowcock.jpg/220px-Himalayan_Snowcock.jpg"},{"name":"Chukar","sci":"Alectoris chukar","url":"/wiki/Chukar","img":"//upload.wikimedia.org/wikipedia/commons/thumb/7/77/Alectoris-chukar-001.jpg/220px-Alectoris-chukar-001.jpg"},{"name":"See-see Partridge","sci":"Ammoperdix griseogularis","url":"/wiki/See-see_Partridge","img":"//upload.wikimedia.org/wikipedia/commons/thumb/d/de/Ammoperdix_griseogularis.jpg/220px-Ammoperdix_griseogularis.jpg"},{"name":"Black Francolin","sci":"Francolinus francolinus","url":"/wiki/Black_Francolin","img":"//upload.wikimedia.org/wikipedia/commons/thumb/9/9d/Black_Francolin.jpg/220px-Black_Francolin.jpg"},{"name":"Painted Francolin","sci":"Francolinus pictus","url":"/wiki/Painted_Francolin","img":"//upload.wikimedia.org/wikipedia/commons/thumb/f/f2/Francolinus_pictus_hm.jpg/220px-Francolinus_pictus_hm.jpg"},{"name":"Chinese Francolin","sci":"Francolinus pintadeanus","url":"/wiki/Chinese_Francolin","img":"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/Francolinus_pintadeanus_hm.jpg/220px-Francolinus_pintadeanus_hm.jpg"},{"name":"Grey Francolin","sci":"Francolinus pondicerianus","url":"/wiki/Grey_Francolin","img":"//upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Grey_Francolin_RWD2.jpg/220px-Grey_Francolin_RWD2.jpg"},{"name":"Swamp Francolin","sci":"Francolinus gularis","url":"/wiki/Swamp_Francolin","img":"//upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Francolinus_gularis_hm.jpg/220px-Francolinus_gularis_hm.jpg"},{"name":"Tibetan Partridge","sci":"Perdix hodgsoniae","url":"/wiki/Tibetan_Partridge","img":"//upload.wikimedia.org/wikipedia/commons/thumb/8/8b/Perdix_hodgsoniae_John_Gould.jpg/220px-Perdix_hodgsoniae_John_Gould.jpg"},{"name":"Himalayan Quail","sci":"Ophrysia superciliosa","url":"/wiki/Himalayan_Quail","img":"//upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Ophrysia_superciliosa.jpg/250px-Ophrysia_superciliosa.jpg"},{"name":"Japanese Quail","sci":"Coturnix japonica","url":"/wiki/Japanese_Quail","img":"//upload.wikimedia.org/wikipedia/commons/thumb/d/db/Japanese_Quail.jpg/250px-Japanese_Quail.jpg"},{"name":"Common Quail","sci":"Coturnix coturnix","url":"/wiki/Common_Quail","img":"//upload.wikimedia.org/wikipedia/commons/thumb/8/87/Coturnix_coturnix_%28Warsaw_zoo%29-1.JPG/220px-Coturnix_coturnix_%28Warsaw_zoo%29-1.JPG"},{"name":"Rain Quail","sci":"Coturnix coromandelica","url":"/wiki/Rain_Quail","img":"//upload.wikimedia.org/wikipedia/commons/thumb/6/60/Coturnix_coromandelica.jpg/220px-Coturnix_coromandelica.jpg"},{"name":"Blue-breasted Quail","sci":"Coturnix chinensis","url":"/wiki/Blue-breasted_Quail","img":"//upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Excalfactoria_chinensis_%28aka%29.jpg/220px-Excalfactoria_chinensis_%28aka%29.jpg"},{"name":"Jungle Bush-Quail","sci":"Perdicula asiatica","url":"/wiki/Jungle_Bush-Quail","img":"//upload.wikimedia.org/wikipedia/commons/thumb/d/d5/Perdicula_asiatica_hm.jpg/220px-Perdicula_asiatica_hm.jpg"},{"name":"Rock Bush-Quail","sci":"Perdicula argoondah","url":"/wiki/Rock_Bush-Quail","img":"//upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Perdicula_argoondah_-Rajasthan%2C_India_-male-8.jpg/220px-Perdicula_argoondah_-Rajasthan%2C_India_-male-8.jpg"},{"name":"Painted Bush-Quail","sci":"Perdicula erythrorhyncha","url":"/wiki/Painted_Bush-Quail","img":"//upload.wikimedia.org/wikipedia/commons/thumb/b/b8/Male_of_Bush_Paited_Quail.jpg/220px-Male_of_Bush_Paited_Quail.jpg"},{"name":"Manipur Bush-Quail","sci":"Perdicula manipurensis","url":"/wiki/Manipur_Bush-Quail","img":"//upload.wikimedia.org/wikipedia/commons/thumb/4/44/ManipurBushQuail.jpg/220px-ManipurBushQuail.jpg"},{"name":"Hill Partridge","sci":"Arborophila torqueola","url":"/wiki/Hill_Partridge","img":"//upload.wikimedia.org/wikipedia/commons/thumb/3/31/Arborophila_torqueola_torqueola_male_1838.jpg/220px-Arborophila_torqueola_torqueola_male_1838.jpg"},{"name":"Chestnut-breasted Partridge","sci":"Arborophila mandellii","url":"/wiki/Chestnut-breasted_Partridge","img":"//upload.wikimedia.org/wikipedia/commons/thumb/0/0b/MandellisTreePartridge.jpg/220px-MandellisTreePartridge.jpg"},{"name":"Rufous-throated Partridge","sci":"Arborophila rufogularis","url":"/wiki/Rufous-throated_Partridge","img":"//upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Arborophila_rufogularis_-_Doi_Inthanon.jpg/220px-Arborophila_rufogularis_-_Doi_Inthanon.jpg"},{"name":"White-cheeked Partridge","sci":"Arborophila atrogularis","url":"/wiki/White-cheeked_Partridge","img":"//upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Arboricola_atrogularis_hm.jpg/220px-Arboricola_atrogularis_hm.jpg"},{"name":"Mountain Bamboo-Partridge","sci":"Bambusicola fytchii","url":"/wiki/Mountain_Bamboo-Partridge","img":"//upload.wikimedia.org/wikipedia/commons/thumb/1/13/Bambusicola_fytchii_-Smithsonian_National_Zoo%2C_Washington%2C_USA-8a.jpg/220px-Bambusicola_fytchii_-Smithsonian_National_Zoo%2C_Washington%2C_USA-8a.jpg"},{"name":"Red Spurfowl","sci":"Galloperdix spadicea","url":"/wiki/Red_Spurfowl","img":"//upload.wikimedia.org/wikipedia/commons/thumb/6/69/RED_SPURFOWL_NHOLE.png/220px-RED_SPURFOWL_NHOLE.png"},{"name":"Painted Spurfowl","sci":"Galloperdix lunulata","url":"/wiki/Painted_Spurfowl","img":"//upload.wikimedia.org/wikipedia/commons/thumb/a/a2/PaintedSpurfowlMF2crop.jpg/220px-PaintedSpurfowlMF2crop.jpg"},{"name":"Blood Pheasant","sci":"Ithaginis cruentus","url":"/wiki/Blood_Pheasant","img":"//upload.wikimedia.org/wikipedia/commons/thumb/0/0d/Blood_Pheasant.jpg/220px-Blood_Pheasant.jpg"},{"name":"Western Tragopan","sci":"Tragopan melanocephalus","url":"/wiki/Western_Tragopan","img":"//upload.wikimedia.org/wikipedia/commons/thumb/e/e7/WesternTragopan.jpg/220px-WesternTragopan.jpg"},{"name":"Satyr Tragopan","sci":"Tragopan satyra","url":"/wiki/Satyr_Tragopan","img":"//upload.wikimedia.org/wikipedia/commons/thumb/1/1c/Satyr_Tragopan_Osaka.jpg/220px-Satyr_Tragopan_Osaka.jpg"}]
''';