import 'package:args/args.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_interactions/interactions.dart';

import 'Utils.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()..addOption('token', abbr: 't', defaultsTo: 'null');
  var result = parser.parse(arguments);

  if (result['token'] == 'null') {
    print('You must provide a token with -t <token>');
    return;
  }
  var names = ['ticket', 'partner', '3e', 'support'];
  var token = result['token'];
  var bot = Nyxx(token, GatewayIntents.all);
  var guild = await bot.fetchGuild(Snowflake(781589560944885781));
  var interact = Interactions(bot);

  var support = '861307167755993118';
  var thirdhand = '861890244524376084';
  var partner = '861890285855965184';
  var review = '';
  var archive = '861894489651019787';

  bot.onMessageReactionAdded.listen((event) async {
    if (event.messageId == Snowflake(861272991894994955)) {
      var user = await event.user.getOrDownload();
      var channel = await guild.createChannel(ChannelBuilder.create(
          name: 'ticket-${user.username}',
          type: ChannelType.text)) as GuildChannel;
      await channel.editChannelPermissionOverrides(
          PermissionOverrideBuilder(0, Snowflake(781589560944885781))
            ..viewChannel = false);
      await channel.editChannelPermissionOverrides(
          PermissionOverrideBuilder(1, Snowflake(user.id))
            ..viewChannel = true
            ..sendMessages = false);

      var choices = MultiselectBuilder('select', [
        MultiselectOptionBuilder('Support', 'support', false),
        MultiselectOptionBuilder('Partenariat', 'partner', false),
        MultiselectOptionBuilder('3e Main', '3e-main', false),
        MultiselectOptionBuilder('Demande de merge (GitHub)', 'review', false)
      ]);
      await bot.httpEndpoints.sendMessage(
          channel.id,
          ComponentMessageBuilder()
            ..components = [
              [choices]
            ]
            ..embeds = [
              EmbedBuilder()
                ..description =
                    'Veuillez choisir votre type d\'aide ${user.mention}'
                ..color = DiscordColor.fromHexString('#66666')
            ]);
      var message = await bot.httpEndpoints
          .sendMessage(channel.id, MessageBuilder()..content = user.mention);
      await message.delete();
    }
  });

  interact
    ..onMultiselectEvent.listen((event) async {
      if (event.interaction.customId == 'select') {
        var guild = bot.guilds.first;
        var choice = event.interaction.values.first;
        var chana = await event.interaction.channel.download();
        var chan =
            guild!.channels.firstWhere((element) => element.id == chana.id)
                as TextGuildChannel;
        await chan.edit(
            ChannelBuilder()..name = '$choice-${chan.name.split('-')[1]}');
        switch (choice) {
          case 'support':
            await changePlace(chan, support, token);
            break;
          case 'partner':
            await changePlace(chan, partner, token);
            break;
          case '3e-main':
            await changePlace(chan, thirdhand, token);
            break;
          case 'review':
            await changePlace(chan, review, token);
        }
        var msg = await event.interaction.message.download();
        await msg.delete();
        var name = chan.permissionOverrides
            .firstWhere((element) => element.permissions.viewChannel == true)
            .id;
        chan.permissionOverrides
            .removeWhere((element) => element.permissions.viewChannel == true);
        await chan
            .editChannelPermissionOverrides(PermissionOverrideBuilder(1, name)
              ..viewChannel = true
              ..sendMessages = true);
        await chan.sendMessage(MessageBuilder.embed(EmbedBuilder()
          ..description =
              '**Voici votre ticket !\nVous pouvez faire `/close` pour le fermer !**'
          ..color = DiscordColor.fromHexString('#66666')));
        await event.respond(
            MessageBuilder.embed(EmbedBuilder()
              ..description = 'Le type de ticket a bien été changé !'
              ..color = DiscordColor.fromHexString('#66666')),
            hidden: true);
      }
    })
    ..registerSlashCommand(SlashCommandBuilder('close', 'Ferme le ticket', [],
        guild: Snowflake(781589560944885781)))
    ..registerSlashCommand(SlashCommandBuilder(
        'real-close', 'Ferme le ticket (STAFF ONLY)', [],
        guild: Snowflake(781589560944885781)))
    ..onSlashCommand.listen((event) async {
      var chan = await event.interaction.channel.download();
      if (event.interaction.name == 'close') {
        var chanName =
            guild.channels.firstWhere((element) => element.id == chan.id).name;
        if (names.contains(chanName.split('-')[0])) {
          var guildChan =
              await event.interaction.channel.download() as GuildChannel;
          var name = guildChan.permissionOverrides
              .firstWhere((element) => element.permissions.viewChannel == true)
              .id;
          guildChan.permissionOverrides.removeWhere(
              (element) => element.permissions.viewChannel == true);
          await guildChan.editChannelPermissionOverrides(
              PermissionOverrideBuilder(1, name)..viewChannel = false);
          await event.respond(MessageBuilder.content('Success'));
          await changePlace(guildChan, archive, token);
        } else {
          await event.respond(
              MessageBuilder.content('This is not a ticket channel'),
              hidden: true);
        }
      } else if (event.interaction.name == 'real-close') {
        var chanName =
            guild.channels.firstWhere((element) => element.id == chan.id).name;
        if (names.contains(chanName.split('-')[0])) {
          var guildChan =
              await event.interaction.channel.download() as GuildChannel;
          await guildChan.delete();
          await event.respond(MessageBuilder()..content = 'Succesfully deleted');
        }
      }
    })
    ..syncOnReady();
}
