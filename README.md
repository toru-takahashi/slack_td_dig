Daily Workflow to export Slack history to TD
====

This workflow ingests Slack history in daily basis, and exports it to TreasureData.

## Requirement

- [Slack Token](https://api.slack.com/web)
  - Access Scope requries **channels.history** and **channels.info**
- [TreasureData APIKEY](https://console.treasuredata.com/app/users/current)

## How to use

First, please set the above credentials by `digdag secrets` command.

```
$ digdag secrets --local --set slack_td.token=xxxx
$ digdag secrets --local --set slack_td.td_apikey=xxxx
```

Second, please put your info into `_export` section in `slack.dig`.

```
  channel_prefix: 'customer-'
  td_database: 'slack'
  td_table: 'history'
```

By `channel_prefix`, this workflow ingests only channels with the prefix.

For example, if you have the following slack public channel, you could get only `customer-td` channel.

```
#customer-td  -> Load
#engineer     -> Skip
#sales        -> Skip
```


Finally, you can run the digdag schedule by the following.

```
$ digdag sched
```
