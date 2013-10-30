import 'dart:html';
import 'dart:core';
import 'dart:async';
import 'dart:convert';

const baseURL = "en.wikipedia.org";

class Features{
  Map<String, Map<String, String>> features;
  
  void add(String group, String attr, String value) {
    if (features.containsKey(group)) {features[group][attr] = value;} 
      else {features[group] = new Map();
          features[group][attr] = value;
      }    
  }
  
  String get(String group, String attr)  => features[group][attr];
  
  bool has(String group, String attr) => features.containsKey(group) && features[group].containsKey(attr);
  
  Features(this.features);
  
  Features.empty (){
    features = new Map();
  }
  
  Features.init (){
    features = {"size":{"size" : 25 }};
  }
}

class Descriptions{
  Map<BirdId, Features> descs;
  
  void add(BirdId id, String group, String attr, String value){
    if (descs.containsKey(id)) {descs[id].add(group, attr,value);}
    else {descs[id] = new Features.empty()..add(group, attr, value);}
  }
  
  void addFeatures(BirdId id, Features features){
    descs[id] = features;
  }
  
  Features getFeatures(BirdId id) => descs[id];
  
  String getAttribute(BirdId id, group, attr) => descs[id].get(group, attr); 
  
  num repDiff(BirdId id, Features rep) => -match(rep, descs[id]);
  
  List<BirdId> get birds => descs.keys.toList();
  
  List<BirdId> sortedBirds(Features rep){
    List<BirdId> sorted =  birds..sort((a,b) => 
                      (repDiff(a, rep).compareTo(repDiff(b, rep))));
    return sorted;
  }
  
  Descriptions.empty() {
    descs = new Map();
  }
}

class BirdId{
  String name, sci, url, img;
  
  String morph='';
  
  BirdId(this.name, this.sci, this.url, this.img);
  
  BirdId.fromMap(Map<String, String> bird){
    name = bird['name'];
    sci = bird['sci'];
    url = bird['url'];
    img = bird['img'];
  }
}


String sizePrompt(String value){
  return "Size : ${value} cm";
}


DivElement sizeInput(Features features) {
  var prompt = new ParagraphElement()..text= sizePrompt("25");
  
  RangeInputElement slider = new RangeInputElement()
              ..min = "0"
              ..max = "120"
              ..value = "25";
  
       slider.onChange.listen((Event event){
       var size = slider.value;
       prompt.text = sizePrompt(size);
       features.add("size", "size", size);
       repUpdate();
        });
  
  
  var div = new DivElement()
              ..children = ([prompt, slider]);
  
  return div;
}



var reported = new Features.init();

var descs = new Descriptions.empty();

void addDesc(BirdId id, Features feat){ 
  descs.addFeatures(id, feat);
//also submit to server
}

var mainColours = ["back","head", "breast"];

Map<String, List<String>> binAttr = {"Tail" : ["long", "forked"], 
                                     "Beak" : ["hooked", "long"]};


Map<String, List<String>> behAttr = {"Seen" : ["flying", "on the ground", "on a branch"],
                                     "Habitat" : ["dry", "forested"]
};

var otherColours=["leg", "beak", "neck"];



String colourString(String col){
  int R = int.parse("0x"+col.substring(1, 3));
  int G = int.parse("0x"+col.substring(3, 5));
  int B = int.parse("0x"+col.substring(5, 7));
  return "($R, $G, $B)";
}

class RGB{
  int R, G, B;
  
  RGB.fromString(String col){
    R = int.parse("0x"+col.substring(1, 3));
    G = int.parse("0x"+col.substring(3, 5));
    B = int.parse("0x"+col.substring(5, 7));
  }
  
  int get r => 2 * R - G - B;
  int get g => 2 * G - R - B;
  int get b => 2 * B - G - R;
  int get w => R + G + B;
  
  num colDiff(RGB that){
    return (r - that.r).abs() + (g - that.g).abs() + (b - that.b).abs() + (w - that.w).abs();
  }
}

num colStringDiff(String fst, scnd){
  var rgb =   new RGB.fromString(fst);
   return rgb.colDiff(new RGB.fromString(scnd));
}

num colMatch(String group, Features rep, desc){
  if (rep.has(group, 'colour') && desc.has(group, 'colour'))
      return -colStringDiff(rep.get(group, 'colour'), desc.get(group, 'colour'));
  return 0;
}

num binMatch(String group, attr, Features rep, desc){
  if (rep.has(group, attr) && desc.has(group, attr)
      && rep.get(group, attr).toLowerCase() == 'true' 
      && desc.get(group, attr).toLowerCase() == 'true') return 10;
  else return 0;
}

num behMatch(String group, attr, Features rep, desc){
  if (rep.has(group, attr) && desc.has(group, attr))
    {if
      (rep.get(group, attr).toLowerCase() == 'true' 
      && desc.get(group, attr).toLowerCase() == 'often') return 10;
    if
    (rep.get(group, attr).toLowerCase() == 'true' 
    && desc.get(group, attr).toLowerCase() == 'rarely') return -5;
    }
  else return 0;
}

num colMatchSum(Features rep, desc){
  num sum = 0;
  for (var group in mainColours){    
      sum += colMatch(group, rep, desc);
    }
  return sum;
}

num behMatchSum(Features rep, desc){
  num sum = 0;
  for (var group in behAttr){
    for (var attr in behAttr[group]){
      sum += behMatch(group, attr, rep, desc);
    }
  }
  return sum;
}

num binMatchSum(Features rep, desc){
  num sum = 0;
  for (var group in binAttr){
    for (var attr in binAttr[group]){
      sum += binMatch(group, attr, rep, desc);
    }
  }
  return sum;
}

num match(Features rep, desc) => binMatchSum(rep, desc)
                                  + behMatchSum(rep, desc)
                                  + colMatchSum(rep, desc);

LIElement checkboxChoose(String group, String name, Features features){
  LIElement item = new LIElement();
  var par = new ParagraphElement();
  par.text = name + ": ";
  var inp = new CheckboxInputElement();
  inp.onChange.listen((Event e){
        String value;
        if (inp.checked) {value = true.toString();} else {value = false.toString();}
        features.add(group, name, value);
        repUpdate();
      });
  par.children.add(inp);
  item.children.add(par);
  return item;
}

LIElement colourChoose(String name, Features features){
  LIElement item = new LIElement();
  var par = new ParagraphElement();
  par.text = name + ": ";
  var inp = new InputElement();
  inp
      ..type = "color"
      ..onChange.listen((Event e){
      features.add("colour", name, inp.value);
        repUpdate();
      });
  par.children.add(inp);
  item.children.add(par);
  return item;
}



UListElement checkboxList(String group, List<String> names, Features features) {
  var ulist = new UListElement();
  names.forEach((String name){
      ulist.children.add(checkboxChoose(group, name, features));
  });
  return ulist;
}

void repUpdate(){
  querySelector("#rep").text = reported.features.toString();
}


List<Element> colourquerySelector(List<String> colours, Features features){
  Iterable<LIElement> colourIter = colours.map((String col){
    return colourChoose(col, features);
  });    

  return colourIter.toList();
}


  List<DivElement> attrListList(Map<String, List<String>> bingps
                                , Features features){
    Iterable<DivElement> iterListList = bingps.keys.map((String group){
      DivElement div = new DivElement();
      div
      ..innerHtml = "<h3>$group:</h3>"
      ..children.add(checkboxList(group, binAttr[group], features));
      return div;
    }); 
    return iterListList.toList();
  }


  var wikiSampleText = '''
      [{"name":"Nicobar Scrubfowl","sci":"Megapodius nicobariensis","url":"/wiki/Nicobar_Scrubfowl","img":"//upload.wikimedia.org/wikipedia/commons/thumb/0/06/Nicobar_Megapode.svg/220px-Nicobar_Megapode.svg.png"},{"name":"Snow Partridge","sci":"Lerwa lerwa","url":"/wiki/Snow_Partridge","img":"//upload.wikimedia.org/wikipedia/commons/thumb/3/34/Lerwa_lerwa.jpg/220px-Lerwa_lerwa.jpg"},{"name":"Szecheny's Partridge","sci":"Tetraophasis szechenyii","url":"/wiki/Szecheny%27s_Partridge","img":"//upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Status_iucn3.1_LC.svg/220px-Status_iucn3.1_LC.svg.png"},{"name":"Tibetan Snowcock","sci":"Tetraogallus tibetanus","url":"/wiki/Tibetan_Snowcock","img":"//upload.wikimedia.org/wikipedia/commons/thumb/0/0d/Tetraogallus_tibetanus.jpg/220px-Tetraogallus_tibetanus.jpg"},{"name":"Himalayan Snowcock","sci":"Tetraogallus himalayensis","url":"/wiki/Himalayan_Snowcock","img":"//upload.wikimedia.org/wikipedia/commons/thumb/c/c8/Himalayan_Snowcock.jpg/220px-Himalayan_Snowcock.jpg"},{"name":"Chukar","sci":"Alectoris chukar","url":"/wiki/Chukar","img":"//upload.wikimedia.org/wikipedia/commons/thumb/7/77/Alectoris-chukar-001.jpg/220px-Alectoris-chukar-001.jpg"},{"name":"See-see Partridge","sci":"Ammoperdix griseogularis","url":"/wiki/See-see_Partridge","img":"//upload.wikimedia.org/wikipedia/commons/thumb/d/de/Ammoperdix_griseogularis.jpg/220px-Ammoperdix_griseogularis.jpg"},{"name":"Black Francolin","sci":"Francolinus francolinus","url":"/wiki/Black_Francolin","img":"//upload.wikimedia.org/wikipedia/commons/thumb/9/9d/Black_Francolin.jpg/220px-Black_Francolin.jpg"},{"name":"Painted Francolin","sci":"Francolinus pictus","url":"/wiki/Painted_Francolin","img":"//upload.wikimedia.org/wikipedia/commons/thumb/f/f2/Francolinus_pictus_hm.jpg/220px-Francolinus_pictus_hm.jpg"},{"name":"Chinese Francolin","sci":"Francolinus pintadeanus","url":"/wiki/Chinese_Francolin","img":"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/Francolinus_pintadeanus_hm.jpg/220px-Francolinus_pintadeanus_hm.jpg"},{"name":"Grey Francolin","sci":"Francolinus pondicerianus","url":"/wiki/Grey_Francolin","img":"//upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Grey_Francolin_RWD2.jpg/220px-Grey_Francolin_RWD2.jpg"},{"name":"Swamp Francolin","sci":"Francolinus gularis","url":"/wiki/Swamp_Francolin","img":"//upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Francolinus_gularis_hm.jpg/220px-Francolinus_gularis_hm.jpg"},{"name":"Tibetan Partridge","sci":"Perdix hodgsoniae","url":"/wiki/Tibetan_Partridge","img":"//upload.wikimedia.org/wikipedia/commons/thumb/8/8b/Perdix_hodgsoniae_John_Gould.jpg/220px-Perdix_hodgsoniae_John_Gould.jpg"},{"name":"Himalayan Quail","sci":"Ophrysia superciliosa","url":"/wiki/Himalayan_Quail","img":"//upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Ophrysia_superciliosa.jpg/250px-Ophrysia_superciliosa.jpg"},{"name":"Japanese Quail","sci":"Coturnix japonica","url":"/wiki/Japanese_Quail","img":"//upload.wikimedia.org/wikipedia/commons/thumb/d/db/Japanese_Quail.jpg/250px-Japanese_Quail.jpg"},{"name":"Common Quail","sci":"Coturnix coturnix","url":"/wiki/Common_Quail","img":"//upload.wikimedia.org/wikipedia/commons/thumb/8/87/Coturnix_coturnix_%28Warsaw_zoo%29-1.JPG/220px-Coturnix_coturnix_%28Warsaw_zoo%29-1.JPG"},{"name":"Rain Quail","sci":"Coturnix coromandelica","url":"/wiki/Rain_Quail","img":"//upload.wikimedia.org/wikipedia/commons/thumb/6/60/Coturnix_coromandelica.jpg/220px-Coturnix_coromandelica.jpg"},{"name":"Blue-breasted Quail","sci":"Coturnix chinensis","url":"/wiki/Blue-breasted_Quail","img":"//upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Excalfactoria_chinensis_%28aka%29.jpg/220px-Excalfactoria_chinensis_%28aka%29.jpg"},{"name":"Jungle Bush-Quail","sci":"Perdicula asiatica","url":"/wiki/Jungle_Bush-Quail","img":"//upload.wikimedia.org/wikipedia/commons/thumb/d/d5/Perdicula_asiatica_hm.jpg/220px-Perdicula_asiatica_hm.jpg"},{"name":"Rock Bush-Quail","sci":"Perdicula argoondah","url":"/wiki/Rock_Bush-Quail","img":"//upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Perdicula_argoondah_-Rajasthan%2C_India_-male-8.jpg/220px-Perdicula_argoondah_-Rajasthan%2C_India_-male-8.jpg"},{"name":"Painted Bush-Quail","sci":"Perdicula erythrorhyncha","url":"/wiki/Painted_Bush-Quail","img":"//upload.wikimedia.org/wikipedia/commons/thumb/b/b8/Male_of_Bush_Paited_Quail.jpg/220px-Male_of_Bush_Paited_Quail.jpg"},{"name":"Manipur Bush-Quail","sci":"Perdicula manipurensis","url":"/wiki/Manipur_Bush-Quail","img":"//upload.wikimedia.org/wikipedia/commons/thumb/4/44/ManipurBushQuail.jpg/220px-ManipurBushQuail.jpg"},{"name":"Hill Partridge","sci":"Arborophila torqueola","url":"/wiki/Hill_Partridge","img":"//upload.wikimedia.org/wikipedia/commons/thumb/3/31/Arborophila_torqueola_torqueola_male_1838.jpg/220px-Arborophila_torqueola_torqueola_male_1838.jpg"},{"name":"Chestnut-breasted Partridge","sci":"Arborophila mandellii","url":"/wiki/Chestnut-breasted_Partridge","img":"//upload.wikimedia.org/wikipedia/commons/thumb/0/0b/MandellisTreePartridge.jpg/220px-MandellisTreePartridge.jpg"},{"name":"Rufous-throated Partridge","sci":"Arborophila rufogularis","url":"/wiki/Rufous-throated_Partridge","img":"//upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Arborophila_rufogularis_-_Doi_Inthanon.jpg/220px-Arborophila_rufogularis_-_Doi_Inthanon.jpg"},{"name":"White-cheeked Partridge","sci":"Arborophila atrogularis","url":"/wiki/White-cheeked_Partridge","img":"//upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Arboricola_atrogularis_hm.jpg/220px-Arboricola_atrogularis_hm.jpg"},{"name":"Mountain Bamboo-Partridge","sci":"Bambusicola fytchii","url":"/wiki/Mountain_Bamboo-Partridge","img":"//upload.wikimedia.org/wikipedia/commons/thumb/1/13/Bambusicola_fytchii_-Smithsonian_National_Zoo%2C_Washington%2C_USA-8a.jpg/220px-Bambusicola_fytchii_-Smithsonian_National_Zoo%2C_Washington%2C_USA-8a.jpg"},{"name":"Red Spurfowl","sci":"Galloperdix spadicea","url":"/wiki/Red_Spurfowl","img":"//upload.wikimedia.org/wikipedia/commons/thumb/6/69/RED_SPURFOWL_NHOLE.png/220px-RED_SPURFOWL_NHOLE.png"},{"name":"Painted Spurfowl","sci":"Galloperdix lunulata","url":"/wiki/Painted_Spurfowl","img":"//upload.wikimedia.org/wikipedia/commons/thumb/a/a2/PaintedSpurfowlMF2crop.jpg/220px-PaintedSpurfowlMF2crop.jpg"},{"name":"Blood Pheasant","sci":"Ithaginis cruentus","url":"/wiki/Blood_Pheasant","img":"//upload.wikimedia.org/wikipedia/commons/thumb/0/0d/Blood_Pheasant.jpg/220px-Blood_Pheasant.jpg"},{"name":"Western Tragopan","sci":"Tragopan melanocephalus","url":"/wiki/Western_Tragopan","img":"//upload.wikimedia.org/wikipedia/commons/thumb/e/e7/WesternTragopan.jpg/220px-WesternTragopan.jpg"},{"name":"Satyr Tragopan","sci":"Tragopan satyra","url":"/wiki/Satyr_Tragopan","img":"//upload.wikimedia.org/wikipedia/commons/thumb/1/1c/Satyr_Tragopan_Osaka.jpg/220px-Satyr_Tragopan_Osaka.jpg"}]
      ''';  
  
  Element birdDisplay(String name, img, url){
    var image = new ImageElement()
              ..src = "http:$img"
              ..height=100
              ..width = 100
              ..classes.add('leftmargin');
    var anchor = new AnchorElement()
          ..href="http://en.wikipedia.org$url"
          ..text= name
          ..target="_blank"
          ..classes.add('leftmargin');
    var div = new DivElement()
              ..children =[image, new ParagraphElement(), anchor, new Element.hr()];
    return div;
  }
  
  Element birdBox(BirdId bird){
    var image = new ImageElement()
    ..src = "http:${bird.img}"
    ..height=100
    ..width = 100
    ..classes.add('leftmargin');
    var anchor = new AnchorElement()
          ..href="http://en.wikipedia.org${bird.url}"
          ..text= bird.name
          ..target="_blank"
          ..classes.add('leftmargin');
    var div = new DivElement()
              ..children =[image, new ParagraphElement(), anchor, new Element.hr()];
    return div;
  }
  
  void binAttributes(Features features){
    querySelector("#bin_attr").children =[];
    binAttr.keys.forEach((String group){
      var div = new DivElement();
      div
      ..innerHtml = "<h3>$group:</h3>"
      ..children.add(checkboxList(group, binAttr[group], features));
      querySelector("#bin_attr").children.add(div);
    });
  }

  void behAttributes(Features features){
    querySelector("#beh_attr").children =[];
    behAttr.keys.forEach((String group){
      var div = new DivElement();
      div
      ..innerHtml = "<h3>$group:</h3>"
      ..children.add(checkboxList(group, behAttr[group], features));
      querySelector("#beh_attr").children.add(div);
    });
  } 
  
  
  void repQueries(Features features, List<BirdId> birdIds){
    querySelector('#size').children = [sizeInput(features)];
    
    querySelector('#colour_list').children = colourquerySelector(mainColours, features);
    
    binAttributes(features);
    
    behAttributes(features);
    
    var submitButton = new ButtonElement()
    ..text="Update Database"
    ..onClick.listen((e) => descInput(birdIds));
    querySelector('#topbar').children = [submitButton];
  }
  
  void descQueries(Features features){
    querySelector('#size').children = [sizeInput(features)];
    
    querySelector('#colour_list').children = colourquerySelector(mainColours, features);
    
    binAttributes(features);
    
    behAttributes(features);
  }
  
  BirdId bird;

  Features descFeatures;
  
  Element birdChooseList(List<BirdId> birdlst, List<BirdId> fullbirdlist){
    var div = new DivElement();
    birdlst.take(15).forEach((b){
      var el = new ParagraphElement()
        ..text= b.name
        ..classes.add('birdchoice')
        ..onClick.listen((e) => birdBar(b, fullbirdlist.take(15).toList(), fullbirdlist));
      div.children.add(el);
    });
    return div;
  }
  
  void birdBar(BirdId firstbird, List<BirdId> birdlist, List<BirdId> fullbirdlist){

    bird = firstbird;
    var inp = new InputElement()
      ..text='search:'
      ..type ='search';
    var brdList = birdChooseList(birdlist, fullbirdlist);
    inp.onInput.listen((e){
        var filterlist = fullbirdlist.where((bird) => (bird.name.toLowerCase().contains(inp.value.toLowerCase()))).take(15).toList();
        if (filterlist.isNotEmpty) {
          brdList = birdChooseList(filterlist.take(15).toList(), fullbirdlist);
          querySelector('#rest').children=[brdList];
        inp.classes.remove('error');
        }
        else inp.classes.add('error');
      });
    

    querySelector('#besthead').text = "Describe:";
    querySelector('#best').children = [birdBox(bird)];
    querySelector('#resthead').text = "Choose bird to describe";
    querySelector('#searchhead').text = "Name:";
    querySelector('#searchbox').children = [inp];
    querySelector('#rest').children=[brdList];
    //querySelector('#sidebar').children= [div];
  }
  
  void descInput(List<BirdId> birds){
   descFeatures = new Features.init();
   descQueries(descFeatures);
   var bestbirds = birds.take(15).toList();
   birdBar(birds[0], bestbirds, birds);   
  }
  
  void submit(){
    descs.addFeatures(bird, descFeatures);
  }
  
  BirdId getBird(Map<String, String> d){ 
    birdIds.forEach((bird){ 
      String morph;
      if (d.containsKey('morph')) {morph = d['morph'];} else morph=''; 
        if (bird.sci == d['sci'] && bird.morph == morph) return bird;
    });
    return new BirdId(d['name'], d['sci'], d['url'], d['img']);
  }  
  
  void getDescs(){
    HttpRequest.getString("../birdDescs").then((s){
      List<Map<String, String>> rawDescs = JSON.decode(s);
      rawDescs.forEach((d) => descs.add(getBird(d), 
                                      d['group'], d['attr'], ['value']));
    });
  }
  
  void putDesc(BirdId b, Features desc){
    var idMap = {'name' : b.name,
             'sci' : b.sci,
             'url' : b.url,
             'img' : b.img,
             'morph' : b.morph};
    desc.features.keys.forEach((group){
      desc.features[group].keys.forEach((attr){
        var upMap = idMap;
        upMap['group']= group;
        upMap['attr'] = attr;
        upMap['value']=desc.get(group, attr);
        HttpRequest.postFormData('../birdDescUpload', upMap);
      });
    });
  }
  
  
  Map<String, num> birdrace = {};
  
  List<Map<String, String>> wikiData = JSON.decode(wikiSampleText);
  
  List<BirdId> birdIds = (wikiData.map((f) => new BirdId.fromMap(f))).toList();
  
  
  
  
void main() {
  
  
  
  
  querySelector("#rep").text = wikiData[0]["img"];
  
  HttpRequest.getString("../wikidata").then((s){
    wikiData = JSON.decode(s);
    birdIds = (wikiData.map((f) => new BirdId.fromMap(f))).toList();
    querySelector("#rep").text=birdIds.length.toString();
    repQueries(reported, birdIds);
  });
  
  HttpRequest.getString("../abundances").then((s){
    birdrace = JSON.decode(s)[0]["abundance"];
//    querySelector("#rep").text=birdrace.toString();
       }
  
  
  );

  
  
  var w = wikiData[0];
  
  querySelector('#best').children.add(birdDisplay(w['name'], w['img'], w['url']));
  
  repQueries(reported, birdIds);
  
}



