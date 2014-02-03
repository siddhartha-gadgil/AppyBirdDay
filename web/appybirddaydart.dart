import 'dart:html';
import 'dart:core';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

// To do:
// 
// Morph
// check attributes, weights (abstract these)

num sizeWt = -10;

num sizeExactMatch = 12.0;

num colWt = 5;

num colPar = 0.4;

num binSeen = 5;

num behCommonSeen = 5;

num behRareSeen = -5;

bool local = false;

const baseURL = "en.wikipedia.org";

void debugOut(String deb){
  var out = new DivElement()..text= deb;
  querySelector('#debugOut').children.add(out); 
}

class Features{
  Map<String, Map<String, String>> features;
  
  void add(String group, String attr, String value) {
    if (features.containsKey(group)) {features[group][attr] = value;} 
      else {features[group] = new Map();
          features[group][attr] = value;
      }    
  }
  
  String get(String group, String attr)  => features[group][attr];
  
  num getNum(String group, String attr) => int.parse(get(group, attr));
  
  bool has(String group, String attr) =>
      features.containsKey(group) && features[group].containsKey(attr);
  
  Features(this.features);
  
  Features.empty (){
    features = new Map();
  }
  
  Features.init (){
    features = {"size":{"size" : "25" }};
  }
  
  Features.copy(Features src){
    features = src.features;
  }
}

class Descriptions{
  Map<BirdId, Features> descs;
  
  void add(BirdId id, String group, String attr, String value){
    if (descs.containsKey(id)) {descs[id].add(group, attr,value);}
    else {descs[id] = new Features.empty()..add(group, attr, value);}
    debugOut('...updated: '+descs.toString());
  }
  
  void addFeatures(BirdId id, Features features){
    descs[id] = features;
  }
  
  bool has(BirdId birdId) => descs.containsKey(birdId);
  
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
  
  String  display(){
    var dsp = "{";
    descs.keys.forEach((birdId) =>
      dsp += "${birdId.name} : ${getFeatures(birdId).features.toString()}, "      
    );
    return dsp+"}";
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
  num numval = int.parse(value);
  Map<String, num> modelSizes = {"Sunbird" : 10,
                                 "Sparrow" : 15,
                                 "Bulbul" : 20,
                                 "Myna"    : 23,
                                 "Crow"    : 43,
                                 "Kite"    : 61,
                                 "Vulture" : 91};
  
  List<String> ord = modelSizes.keys.toList();
  ord.sort((x, y) => ((modelSizes[x]-numval).abs()).compareTo((modelSizes[y]-numval).abs()));
  
  String closest = ord[0];
  
  return "  ${value} cm (~ $closest=${modelSizes[closest]}cm)";
}

void initInp(InputElement inp, Features features, String group, attr){
  if (features.has(group, attr)) inp.value = features.get(group, attr);
}

SpanElement sizeInput(Features features, [bool rep=true]) {
  var prompt = new ParagraphElement()..text= sizePrompt("25");
  
  if (features.has('size', 'size')) prompt.text = sizePrompt(features.get('size', 'size'));
  
  RangeInputElement slider = new RangeInputElement()
              ..min = "0"
              ..max = "120"
              ..value = "25";
      
      initInp(slider, features, 'size', 'size');
      slider.onChange.listen((Event event){
      var size = slider.value;
      prompt.text = sizePrompt(size);
      features.add("size", "size", size);
      if (rep) {birdSort(features);
       repUpdate();}
        });
  
  
  var span = new SpanElement()
              ..children = ([prompt, slider]);
  
  return span;
}



var reported = new Features.init();

var descrips = new Descriptions.empty();

void addDesc(BirdId id, Features feat){ 
  descrips.addFeatures(id, feat);
//also submit to server
}

var mainColours = ["back","head", "breast"];

Map<String, List<String>> binAttr = {"Tail" : ["long", "forked", "upright", "fan"], 
                                     "Beak" : ["hooked", "long", "curved"],
                                      "Legs" : ["long"], 
                                      "Feet": ["webbed", "spread-out"],
                                      "Crest/cap" : ["crest", "cap"]
};


Map<String, List<String>> behAttr = {"Seen" : ["flying overhead",
                                               "on the ground",
                                               "on a branch",
                                               "swimming"],
                                     "Habitat" : ["grassland/field", "forested", "near waterbody",
                                                  "marshy", 
                                                  "hilly", "urban"],
                                     "Flight" : ["gliding", "catching insects", "swift"]
};

var otherColours=["leg", "beak", "neck", "tail", "wing-underside", "wing-tips"];



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
    return ((r - that.r).abs() + (g - that.g).abs() + (b - that.b).abs() + (w - that.w).abs())/750;
  }
}

num colStringDiff(String fst, scnd){
  var rgb =   new RGB.fromString(fst);
   return rgb.colDiff(new RGB.fromString(scnd));
}

num colMatch(String group, Features rep, desc){
  return (rep.has(group, 'colour') && desc.has(group, 'colour')) ?
      colWt * (colPar - colStringDiff(rep.get(group, 'colour'), desc.get(group, 'colour')))
      : 0;
}

num binMatch(String group, attr, Features rep, desc){
  if (rep.has(group, attr) && desc.has(group, attr)
      && rep.get(group, attr).toLowerCase() == 'true' 
      && desc.get(group, attr).toLowerCase() == 'true') {return binSeen;}
  else return 0;
}

num behMatch(String group, attr, Features rep, desc){
  if (rep.has(group, attr) && desc.has(group, attr))
    {if
      (rep.get(group, attr).toLowerCase() == 'true' 
      && desc.get(group, attr).toLowerCase() == 'often') return behCommonSeen;
    if
    (rep.get(group, attr).toLowerCase() == 'true' 
    && desc.get(group, attr).toLowerCase() == 'rarely') return behRareSeen;
    }
  return 0;
}

num sizeMatch(Features rep, desc){
  num out =  sizeExactMatch + (desc.has('size', 'size') ? 
      log((desc.getNum('size', 'size')/ rep.getNum('size', 'size'))).abs() *sizeWt
        : 0.5 * sizeWt); 
  debugOut(out.toString());
  return out;
}

num colMatchSum(Features rep, desc){
  num sum = 0;
  for (var group in mainColours){    
      sum += colMatch(group, rep, desc);
    }
  
  for (var group in otherColours){    
    sum += colMatch(group, rep, desc);
  }
  return sum;
}

num behMatchSum(Features rep, desc){
  num sum = 0;
  for (var group in behAttr.keys){
    for (var attr in behAttr[group]){
      sum += behMatch(group, attr, rep, desc);
    }
  }
  debugOut(sum.toString());
  return sum;
}

num binMatchSum(Features rep, desc){
  num sum = 0;
  for (var group in binAttr.keys){
    for (var attr in binAttr[group]){
      sum += binMatch(group, attr, rep, desc);
    }
  }
  debugOut(sum.toString());
  return sum;
}

num match(Features rep, desc) => binMatchSum(rep, desc)
                                  + behMatchSum(rep, desc)
                                  + colMatchSum(rep, desc) 
                                  + sizeMatch(rep, desc);

LIElement checkboxChoose(String group, String name, Features features, [bool rep=true]){
  LIElement item = new LIElement();
  var par = new ParagraphElement();
  par.text = name;
  var inp = new CheckboxInputElement();
  initInp(inp, features, group, name);
  inp.onChange.listen((Event e){
        String value = inp.checked ? 'true' : 'false';
        features.add(group, name, value);
        if (rep) {birdSort(features);
        repUpdate();}
      });
  par.children.add(inp);
  item.children.add(par);
  return item;
}

LIElement colourChoose(String name, Features features, [bool rep=true]){
  LIElement item = new LIElement();
  var par = new ParagraphElement();
  par.text = name;
  var inp = new InputElement();
  initInp(inp, features, 'colour', name);
  inp
      ..type = "color"
      ..onChange.listen((Event e){
      features.add("colour", name, inp.value);
      if (rep){birdSort(features);
        repUpdate();}
      });
  par.children.add(inp);
  item.children.add(par);
  return item;
}



UListElement checkboxList(String group, List<String> names, Features features, [bool rep=true]) {
  var ulist = new UListElement();
  names.forEach((String name){
      ulist.children.add(checkboxChoose(group, name, features, rep));
  });
  return ulist;
}

void repUpdate(){
  querySelector("#rep").text = reported.features.toString()+"\n"+descrips.display();
  var bestBirds = birdIds.take(12);
  querySelector('#best').children = bestBirds.map(birdBox).toList();
}


List<Element> colourquerySelector(List<String> colours, Features features, [bool rep=true]){
  Iterable<LIElement> colourIter = colours.map((String col){
    return colourChoose(col, features, rep);
  });    

  return colourIter.toList();
}


  List<DivElement> attrListList(Map<String, List<String>> bingps
                                , Features features){
    Iterable<DivElement> iterListList = bingps.keys.map((String group){
      DivElement div = new DivElement();
      div
      ..innerHtml = "<h3>$group</h3>"
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
  
  void binAttributes(Features features, [bool rep=true]){
    querySelector("#bin_attr").children =[];
    binAttr.keys.forEach((String group){
      var div = new DivElement();
      div
      ..innerHtml = "<h3>$group</h3>"
      ..children.add(checkboxList(group, binAttr[group], features, rep));
      querySelector("#bin_attr").children.add(div);
    });
  }

  void behAttributes(Features features, [bool rep=true]){
    querySelector("#beh_attr").children =[];
    behAttr.keys.forEach((String group){
      var div = new DivElement();
      div
      ..innerHtml = "<h3>$group</h3>"
      ..children.add(checkboxList(group, behAttr[group], features, rep));
      querySelector("#beh_attr").children.add(div);
    });
  } 
  
  void behDescAttributes(Features features){
    querySelector("#beh_attr").children =[];
    behAttr.keys.forEach((String group){
      var ul = new UListElement();
      var div = new DivElement()
      ..innerHtml = "<h3>$group:</h3>";
      div.children.add(ul);
      behAttr[group].forEach((attr){
        var prompt = new SpanElement()..text ="$attr";
        var choiceButtons = new UListElement();
        var li = new LIElement()..children = [prompt, choiceButtons, new ParagraphElement()];
        ul.children.add(li);
        var choices = ['often', 'sometimes', 'rarely'];
        choices.forEach((choice){
        var button = new RadioButtonInputElement()
              ..name = group+":"+ attr
              ..value = choice
              ..onClick.listen((e) => 
                  features.add(group , attr, choice));
        var choicePrompt = new LIElement()..text = choice;
        choicePrompt.children.add(button);
        choiceButtons.children.add(choicePrompt);
        });
      });
      querySelector("#beh_attr").children.add(div);
    });
  } 
  
  void repQueries(){
    debugOut(descrips.display());
    
    querySelector('#subt').text = 
        "Select prominent features that you have observed. The software guesses based on how well these match with the description.";
    
    querySelector('#size').children = [sizeInput(reported)];
    
    querySelector('#colour_list').children = colourquerySelector(mainColours, reported);
    
    querySelector('#other_colour_list').children = colourquerySelector(otherColours, reported);
    
    binAttributes(reported);
    
    behAttributes(reported);
    
    var updateButton = new ButtonElement()
    ..text="Update Database"
    ..onClick.listen((e) => descInput(birdIds));
    querySelector('#topbar').children = [updateButton];
    
    var bestBirds = birdIds.take(12);
    querySelector('#best').children = bestBirds.map(birdBox).toList();
    querySelector('#besthead').text = "Best Matches";
    querySelector('#resthead').text = "";
    querySelector('#searchhead').text = "";
    querySelector('#searchbox').children = [];
    querySelector('#rest').children=[];
    
    querySelector('#queryfoot').children = [];
  }
  
  void descQueries(Features features){
    querySelector('#subt').text = 
        "Select prominent features of the bird. You need not describe features that are unlikely to be noticed.";
    
    querySelector('#size').children = [sizeInput(features, false)];
    
    querySelector('#colour_list').children = colourquerySelector(mainColours, features, false);
    
    querySelector('#other_colour_list').children = colourquerySelector(otherColours, features, false);
    
    binAttributes(features, false);
    
    behDescAttributes(features);
    
    var identButton = new ButtonElement()
    ..text="Identify Bird"
    ..onClick.listen((e) => repQueries());
    querySelector('#topbar').children = [identButton];
    
    var morph = new SpanElement()..text ="Morph"..classes.add("inp");
    
    var morphInput= new InputElement()..text="morph"
        ..size=10
        ..classes.add("inp");
    morphInput.onChange.listen((e) => birdChosen.morph = morphInput.value);

    
    
    var submitButton = new ButtonElement()
      ..text="save description"
      ..classes.add('input')
      ..onClick.listen((e) => submit(features));
    querySelector('#queryfoot').children =[morph, morphInput, submitButton];
  }
  
  BirdId birdChosen;

  Features descFeatures = new Features.empty();
  
  Element birdChooseList(List<BirdId> birdlst, List<BirdId> fullbirdlist, Features features){
    var div = new DivElement();
    birdlst.take(15).forEach((b){
      var el = new ParagraphElement()
        ..text= b.name
        ..classes.add('birdchoice')
        ..onClick.listen((e){           
        birdBar(b, fullbirdlist.take(15).toList(), fullbirdlist, features);});
      div.children.add(el);
    });
    return div;
  }
  
  void birdBar(BirdId firstbird, List<BirdId> birdlist, List<BirdId> fullbirdlist, Features features){
    if (descrips.has(firstbird)) {
      features = new Features.copy(descrips.getFeatures(firstbird));
      descQueries(features);}
    birdChosen = firstbird;
    var inp = new InputElement()
      ..text='search:'
      ..type ='search';
    var brdList = birdChooseList(birdlist, fullbirdlist, features);
    inp.onInput.listen((e){
        var filterlist = inp.value == ''  
           ? fullbirdlist.where((bird) => !(descrips.descs.keys.contains(bird)))
           : fullbirdlist.where((bird) => (bird.name.toLowerCase().contains(inp.value.toLowerCase()))).take(15).toList();
        if (filterlist.isNotEmpty) {
          brdList = birdChooseList(filterlist.take(15).toList(), fullbirdlist, features);
          querySelector('#rest').children=[brdList];
        inp.classes.remove('error');
        }
        else inp.classes.add('error');
      });
    

    querySelector('#besthead').text = "Describe";
    querySelector('#best').children = [birdBox(birdChosen)];
    querySelector('#resthead').text = "Choose bird to describe";
    querySelector('#searchhead').text = "Name";
    querySelector('#searchbox').children = [inp];
    querySelector('#rest').children=[brdList];
    //querySelector('#sidebar').children= [div];
  }
  
  void descInput(List<BirdId> birds){
    descFeatures = new Features.init();
    descQueries(descFeatures);
    var bestbirds = birds.where((bird) => !(descrips.descs.keys.contains(bird))).toList();
    birdBar(bestbirds[0], bestbirds, birds, descFeatures);   
  }
  
  void submit(Features features){
    descrips.addFeatures(birdChosen, features);
    if (!local) updateDesc(birdChosen, features);
    querySelector("#descs").text = descrips.display();
    descInput(birdIds);
  }
  
  BirdId getBird(Map<String, String> d){ 
    var brd = new BirdId(d['name'], d['sci'], d['url'], d['img']);
    String morph = d.containsKey('morph') ? d['morph'] : ''; 
    birdIds.forEach((bird){       
      if ((bird.sci == d['sci']) && (bird.morph == morph)) brd = bird;
    });
    return brd;
  }  

  /*
  void getDescs(Descriptions descps){
    HttpRequest.getString("../birdDescs").then((s){
      debugOut("Json:"+s.toString());
      List<Map<String, String>> rawDescs = JSON.decode(s);
      debugOut("parsed" +rawDescs.toString());
      rawDescs.forEach((d) => descps.add(getBird(d), 
                                      d['group'], d['attr'], d['value']));
    });
    debugOut("Descriptions: "+descps.descs.toString());
  }
  
  */
  
  Map <String, String> birdIdMap(BirdId b) => {"sci" : b.sci, "morph" : b.morph};
  
  
  Future<HttpRequest> clearBird(BirdId b){
    return HttpRequest.postFormData('../birdRemove', birdIdMap(b));
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
  
  Future<HttpRequest> updateDesc(BirdId b, Features desc) => clearBird(b).then((e) => putDesc(b, desc));
  
  
  Map<String, num> birdrace = {};
  
  num abundance(String sci) =>
    birdrace.containsKey(sci) ? 1+birdrace[sci] : 1;
    
  num matchBird(BirdId birdId, Features rep){ 
      if (descrips.has(birdId)) debugOut(birdId.name);
      return descrips.has(birdId) ? 
          match(rep, descrips.descs[birdId]) + abundance(birdId.sci) :
            abundance(birdId.sci);}
  
  void birdSort(Features features) => birdIds.sort((x,y) => matchBird(y, features).compareTo(matchBird(x, features)));        
          
  List<Map<String, String>> wikiData = JSON.decode(wikiSampleText);
  
  List<BirdId> birdIds = (wikiData.map((f) => new BirdId.fromMap(f))).toList();
  
  


void main() {
  
  var sse = new EventSource("../logs")..onMessage.listen((event) => debugOut('boing'+event.data));
  
  querySelector('#cleartrace').onClick.listen((event) =>
      querySelector('#debugOut').children = []);
  
  if (!local) {
    HttpRequest.getString("../abundances").then((s){
      birdrace = JSON.decode(s)[0]["abundance"];
      //   debugOut(birdrace.toString());
    }   
    ).then((p){
  HttpRequest.getString("../wikidata").then((s){
    wikiData = JSON.decode(s);
    birdIds = (wikiData.map((f) => new BirdId.fromMap(f))).toList();
    birdSort(new Features.empty());
//    querySelector("#rep").text=birdIds.length.toString();
  }).then((e){  
  HttpRequest.getString("../birdDescs").then((s){
    List<Map<String, String>> rawDescs = JSON.decode(s);
    rawDescs.forEach((d) => descrips.add(getBird(d), 
        d['group'], d['attr'], d['value']));          
  debugOut("Descriptions" + descrips.display());  
  repQueries();
  });});});}
  else repQueries();
}


