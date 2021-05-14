package onlinemod;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxSound;
import flash.media.Sound;
import lime.media.AudioBuffer;
import flixel.ui.FlxBar;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxAxes;
import flixel.util.FlxTimer;

import haxe.io.Bytes;
import openfl.utils.ByteArray;
import sys.io.File;
import sys.io.FileOutput;
import sys.FileSystem;

using StringTools;

class OnlineLoadState extends MusicBeatState
{
  var loadingText:FlxText;
  var fileSizeText:FlxText;
  var loadingBar:FlxBar;
  var progress:Float = 0;
  // var fileSize:Int = 0;

  var customSong:Bool;

  var jsonInput:String;
  var folder:String;

  var voices:FlxSound;
  var inst:Sound;

  var loadedVoices:Bool = false;
  var loadedInst:Bool = false;

  var weeks:Map<String, Int> = ["tutorial" => 1,
    "the-fitnessgram-tutorial" => 1,
    "the fitnessgram tutorial" => 1,
    "bopeebo" => 1,
    "fresh" => 1,
    "dadbattle" => 1,
    "spooky-month" => 2,
    "spooky month" => 2,
    "spookeez" => 2,
    "south" => 2,
    "eerie" => 2,
    "toadhemian-rhapsody" => 2,
    "toadhemian rhapsody" => 2,
    "monster" => 2,
    "pico" => 3,
    "philly" => 3,
    "blammed" => 3,
    "pico-again" => 3,
    "pico again" => 3,
    "pico-but-three" => 3,
    "pico but three" => 3,
    "llamas-with-hats" => 3,
    "llamas with hats" => 3,
    "satin-panties" => 4,
    "high" => 4,
    "milf" => 4,
    "gas-gas-gas" => 4,
    "gas gas gas" => 4,
    "spider-dance" => 4,
    "spider dance" => 4,
    "bad-apple" => 4,
    "bad apple" => 4,
    "something-spiteful" => 4,
    "something spiteful" => 4,
    "cocoa" => 5,
    "eggnog" => 5,
    "objection" => 5,
    "winter-horrorland" => 5,
    "touch-tone-telephone" => 5,
    "touch tone telephone" => 5,
    "senpai" => 6,
    "roses" => 6,
    "thorns" => 6,
    "four-brave-knights" => 7,
    "four brave knights" => 7,
    "space-pirates" => 7,
    "space pirates" => 7,
    "race-around-the-world" => 7,
    "race around the world" => 7
  ];

  public function new(jsonInput:String, folder:String)
  {
    super();

    this.jsonInput = jsonInput;
    this.folder = folder;
  }

  override function create()
  {
    var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('online_bg2'));
		add(bg);


    loadingText = new FlxText(FlxG.width/4, FlxG.height/2 - 36, FlxG.width, "Downloading Chart...");
    loadingText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    add(loadingText);


    fileSizeText = new FlxText(FlxG.width/4, FlxG.height/2 - 32, FlxG.width/2, "?/?");
    fileSizeText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    add(fileSizeText);


    loadingBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 640, 10, this, 'progress', 0, 1);
    loadingBar.createFilledBar(FlxColor.RED, FlxColor.LIME, true, FlxColor.BLACK);
    loadingBar.screenCenter(FlxAxes.XY);
    add(loadingBar);


    super.create();


    OnlinePlayMenuState.receiver.HandleData = HandleData;


    new FlxTimer().start(transIn.duration, (timer:FlxTimer) -> {
			Sender.SendPacket(Packets.READY_DOWNLOAD, [], OnlinePlayMenuState.socket);
		});
  }

  override function update(elapsed:Float)
  {
    if (OnlinePlayMenuState.receiver.packetId == Packets.SEND_CHART || OnlinePlayMenuState.receiver.packetId == Packets.SEND_VOICES
      || OnlinePlayMenuState.receiver.packetId == Packets.SEND_INST)
    {
      if (OnlinePlayMenuState.receiver.varLength > 4)
      {
        var fileSize:Int = OnlinePlayMenuState.receiver.varLength - 4;
        var bytesReceived:Int = OnlinePlayMenuState.receiver.bufferedBytes - 5;
        progress = Math.min(1, bytesReceived / fileSize);

        if (fileSize > 1000000) //MB
        {
          fileSizeText.text = Std.int(bytesReceived/10000)/100 + "/" + Std.int(fileSize/10000)/100 + "MB";
        }
        else //KB
        {
          fileSizeText.text =  Std.int(bytesReceived/10)/100 + "/" + Std.int(fileSize/10)/100 + "KB";
        }
      }
    }

    switch (OnlinePlayMenuState.receiver.packetId)
    {
      case Packets.SEND_CHART:
        loadingText.text = "Downloading Chart...";
      case Packets.SEND_VOICES:
        loadingText.text = "Downloading Voices...";
      case Packets.SEND_INST:
        loadingText.text = "Downloading Instrumental...";
    }

    super.update(elapsed);
  }

  function HandleData(packetId:Int, data:Array<Dynamic>)
  {
    switch (packetId)
    {
      case Packets.SEND_CHART:
        var file:Bytes = cast(data[0], Bytes);

        PlayState.SONG = Song.parseJSONshit(file.toString());
        trace("DOWNLOADED CHART!!!");

        PlayState.isStoryMode = false;

        // Set difficulty
        PlayState.storyDifficulty = 1;
        if (StringTools.endsWith(jsonInput.toLowerCase(), '-hard'))
        {
          PlayState.storyDifficulty = 2;
        }
        else if (StringTools.endsWith(jsonInput.toLowerCase(), '-easy'))
        {
          PlayState.storyDifficulty = 0;
        }

        if (FileSystem.exists(Paths.json(folder.toLowerCase() + '/' + jsonInput.toLowerCase()))) // In case of a vanilla song
        {
          customSong = false;

          loadVoices('assets/songs/${folder.toLowerCase()}/Voices.ogg');
          loadInst('assets/songs/${folder.toLowerCase()}/Inst.ogg');

          // Set week
          PlayState.storyWeek = weeks[folder.toLowerCase()];
          Paths.setCurrentLevel("week" + PlayState.storyWeek);
        }
        else // In case of a custom song
        {
          customSong = true;

          FileSystem.createDirectory('assets/onlinedata/data/${folder.toLowerCase()}');
          File.saveBytes('assets/onlinedata/data/${folder.toLowerCase()}/${jsonInput.toLowerCase()}.json', file);

          if (FileSystem.exists('assets/onlinedata/songs/${PlayState.SONG.song.toLowerCase()}/Voices.ogg')) // If Voices.ogg has already been downladed
            loadVoices('assets/onlinedata/songs/${PlayState.SONG.song.toLowerCase()}/Voices.ogg');
          else
            requestVoices();

          if (FileSystem.exists('assets/onlinedata/songs/${PlayState.SONG.song.toLowerCase()}/Inst.ogg')) // If Inst.ogg has already been downloaded
            loadInst('assets/onlinedata/songs/${PlayState.SONG.song.toLowerCase()}/Inst.ogg');
          else
            requestInst();
        }

      case Packets.SEND_VOICES:
        var file:Bytes = cast(data[0], Bytes);

        FileSystem.createDirectory('assets/onlinedata/songs/${PlayState.SONG.song.toLowerCase()}');
        File.saveBytes('assets/onlinedata/songs/${PlayState.SONG.song.toLowerCase()}/Voices.ogg', file);

        voices = new FlxSound().loadEmbedded(Sound.fromAudioBuffer(AudioBuffer.fromBytes(file)));

        loadedVoices = true;
        checkComplete();
        trace("DOWNLOADED VOICES!!!");

      case Packets.SEND_INST:
        var file:Bytes = cast(data[0], Bytes);

        FileSystem.createDirectory('assets/onlinedata/songs/${PlayState.SONG.song.toLowerCase()}');
        File.saveBytes('assets/onlinedata/songs/${PlayState.SONG.song.toLowerCase()}/Inst.ogg', file);

        inst = Sound.fromAudioBuffer(AudioBuffer.fromBytes(file));

        loadedInst = true;
        checkComplete();
        trace("DOWNLOADED INST!!!");

      case Packets.DENY:
        FlxG.switchState(new OnlinePlayMenuState("Server couldn't send file"));

      // Normal network handlers
      case Packets.BROADCAST_CHAT_MESSAGE:
        var id:Int = data[0];
        var message:String = data[1];

        OnlineLobbyState.RegisterChatMessage('<${OnlineLobbyState.clients[id]}> $message');
      case Packets.PLAYER_LEFT:
        var id:Int = data[0];
        var nickname:String = OnlineLobbyState.clients[id];

        OnlineLobbyState.removePlayer(id);
        OnlineLobbyState.RegisterChatMessage('$nickname left the game', FlxColor.YELLOW);
    }
  }

  function loadVoices(path:String)
  {
    loadingText.text = "Loading Voices...";

    voices = new FlxSound().loadEmbedded(Sound.fromFile(path));

    loadedVoices = true;
    checkComplete();
  }

  function requestVoices()
  {
    Sender.SendPacket(Packets.REQUEST_VOICES, [], OnlinePlayMenuState.socket);
  }

  function loadInst(path:String)
  {
    loadingText.text = "Loading Instrumental...";

    inst = Sound.fromFile(path);

    loadedInst = true;
    checkComplete();
  }

  function requestInst()
  {
    Sender.SendPacket(Packets.REQUEST_INST, [], OnlinePlayMenuState.socket);
  }


  function checkComplete()
  {
    if (loadedVoices && loadedInst)
    {
      LoadingState.loadAndSwitchState(new OnlinePlayState(customSong, voices, inst));
    }
  }
}
