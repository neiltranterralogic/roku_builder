# RokuBuilder

A tool to help with Roku Development. Assists witht he following tasks:

 * Sideloading
 * Packaging
 * Testing
  * Deeplink testing
  * Intergration test scripting


## Installation

Install it yourself with:

    $ gem install roku_builder

## Usage

#### Configuration

The gem must have a configuration file. To generate this file you can runn the
following command:

    $ roku --configure

This will create the file '~/roku_config.rb' with a default configuration.
Edit this file to add appropriate values. The following are default
configuration options:

 * device_info: information for accessing the device
 * device_info -> ip: ip address of the device
 * device_info -> user: dev username for the roku device
 * device_info -> password: dev password for the roku device

 * projects: this is a hash of project objects
 * projects -> default: the key for the default project

 Each project has the following options:
 * repo_dir: full path of the git repository the houses the roku app
 * app_name: Name used when packaging the app
 * production: a default stage (see below)
 * staging: a default stage (see below)
 * testing: configuration for testing
 * testing -> branch: git referance used for testing

#### Stages

The defualt configuration file has two stages, production and staging. Each has
a stage a git referance (branch) and a key that is used for packaging that
stage. Each key consists of the password for the key (password) and a package
that has been signed with the key (keyed_pkg). You can add or remove as many
stages as you require. You have to have at least one stage to package your app.

#### Sideloading

There are three ways to side load the app. You can sideload based on a stage,
an arbitrary git referance or the working directory.

To sideload a stage you can run the following command:

    $ roku --sideload --stage production

This will sideload the production stage. By default the production stage is
used. So the above is equivalent to the following:

    $ roku --sideload

and:

    $ roku -l

To sideload via a git referance you can run the following command

    $ roku --sideload --ref master

This will sideload the master branch. The following is equivalent:

    $ roku -lr master

To sideload the current working directory you can run the following:

    $ roku --sideload --working

or:

    $ roku -lw

If you choose to sideload via stage or git referance then the roku tool with
stash any changes in the working directory and then apply the stash after. From
time to time there may be an issue with this and you will have to clear the
stash manually.

#### Packaging

To package an app you need to have at least on stage set up in your
configuration file. Once you have that setup then you can run the following:

    $ roku --package --stage production

or:

    $ roku -ps production

This will automatically update the manifest file with a nuw build number. If
you do not want to update the manifest then you can use the option
--no-manifest-update (-n). Example:

    $ roku -pns staging

#### Testing

There are a few tools that can be used for testing. The testing command will
sideload the branch defined in the testing config. It will then connect to the
device via telnet and look for the following strings and prints everything
inbetween them:

Start delimiter: \*\*\*\*\* STARTING TESTS \*\*\*\*\*

End delimiter: \*\*\*\*\* ENDING TESTS \*\*\*\*\*

This is designed to be used with the brstest library. Ensure that if you use
this that the app the prints out a sufficent number of lines after the tests
are run otherwise it will just grab the test run from last time.

Another tool for testing is the navigate command. You can use this to script
navigation on the roku console. The command is used as follows:

    $ roku --navigate <command>

The possible commands are as follows:

 * up
 * down
 * right
 * left
 * select
 * back
 * home
 * rew
 * ff
 * play
 * replay

There is also a command that will allow you to send text to the roku. It is
used as follows:

    $ roku --type <text>

#### Other Tools

You can restart the roku device using the following command:

    $ roku --restart

You can deeplink into your app using the following command:

    $ roku --deeplink --mgid <mgid> --content-type <content type>

This is currently setup to work with one specific app. It will be generalized
in the future.

You can delete the currently sideloaded app using the following command:

    $ roku --delete

You can use a differnt configuration file useing the following option:

    & roku --delete --config <path>

This path will be expanded so you do not have to use the full path

## Projects

The project used in the above examples is a smart default. If you are in a
project directory then it will use that project. If you not then it will use
the defualt that you have defined in your config. You can define what project
you want the command to be run on using the --project option:

    $ roku -lw --project project1

or:

    $ roku -lw -P project1

## Improvements

 * allow start and end delimiter to be configured
 * generalize deeplinking options

## Contributing

1. Fork it ( https://github.com/[my-github-username]/roku_builder/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
