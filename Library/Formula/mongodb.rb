require "formula"

class Mongodb < Formula
  homepage "https://www.mongodb.org/"

  stable do
    url "https://fastdl.mongodb.org/src/mongodb-src-r2.6.5.tar.gz"
    sha1 "f5a68505a0de1152b534d62a8f0147d258d503a0"

    # Review this patch with the next stable release.
    # Note it is a different patch to the one applied to all builds further below.
    # This is already fixed in the devel & HEAD builds.
    if MacOS.version == :yosemite
      patch do
        url "https://github.com/mongodb/mongo/commit/759b6e8.diff"
        sha1 "63d901ac81681fbe8b92dc918954b247990ab2fb"
      end
    end
  end

  bottle do
    revision 2
    sha1 "e6da509908fdacf9eb0f16e850e0516cd0898072" => :yosemite
    sha1 "5ab96fe864e725461eea856e138417994f50bb32" => :mavericks
    sha1 "193e639b7b79fbb18cb2e0a6bbabfbc9b8cbc042" => :mountain_lion
  end

  devel do
    url "https://fastdl.mongodb.org/src/mongodb-src-r2.7.8.tar.gz"
    sha1 "58bc953e4492fa70254f0b63a3ab64a99f51aa32"

    depends_on "go" => :build

  end

  # HEAD is currently failing. See https://jira.mongodb.org/browse/SERVER-15555
  head "https://github.com/mongodb/mongo.git"

  option "with-boost", "Compile using installed boost, not the version shipped with mongodb"

  depends_on "boost" => :optional
  depends_on :macos => :snow_leopard
  depends_on "scons" => :build
  depends_on "openssl" => :optional

  # Review this patch with each release.
  # This modifies the SConstruct file to include 10.10 as an accepted build option.
  if MacOS.version == :yosemite
    patch do
      url "https://raw.githubusercontent.com/DomT4/scripts/fbc0cda/Homebrew_Resources/Mongodb/mongoyosemite.diff"
      sha1 "f4824e93962154aad375eb29527b3137d07f358c"
    end
  end

  resource "mongotools" do
      url "https://github.com/mongodb/mongo-tools/archive/2.7.8.tar.gz"
      sha1 "1f2232c7bdc8af9e35e6c293c49021ba785944c9"
  end

  def install

    # Build tools
    #
    unless build.stable?
      resource("mongotools").stage do
        # system ". ./set_gopath.sh"
        tools = %w[bsondump mongostat mongofiles mongoexport mongoimport mongorestore mongodump mongotop mongooplog]
        tools.each do |tool|
          system ". ./set_gopath.sh ; go build  -o #{buildpath}/src/mongo-tools/#{tool} #{tool}/main/#{tool}.go"
        end
      end
    end

    # Build everything else
    #
    args = %W[
      --prefix=#{prefix}
      -j#{ENV.make_jobs}
      --cc=#{ENV.cc}
      --cxx=#{ENV.cxx}
      --osx-version-min=#{MacOS.version}
    ]

    # --full installs development headers and client library, not just binaries
    # (only supported pre-2.7)
    args << "--full" if build.stable?
    args << "--use-system-boost" if build.with? "boost"
    args << "--64" if MacOS.prefer_64_bit?

    if build.with? "openssl"
      args << "--ssl" << "--extrapath=#{Formula["openssl"].opt_prefix}"
    end
    scons "install", *args

    (buildpath+"mongod.conf").write mongodb_conf
    etc.install "mongod.conf"

    (var+"mongodb").mkpath
    (var+"log/mongodb").mkpath
  end

  def mongodb_conf; <<-EOS.undent
    systemLog:
      destination: file
      path: #{var}/log/mongodb/mongo.log
      logAppend: true
    storage:
      dbPath: #{var}/mongodb
    net:
      bindIp: 127.0.0.1
    EOS
  end

  plist_options :manual => "mongod --config #{HOMEBREW_PREFIX}/etc/mongod.conf"

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>ProgramArguments</key>
      <array>
        <string>#{opt_bin}/mongod</string>
        <string>--config</string>
        <string>#{etc}/mongod.conf</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>KeepAlive</key>
      <false/>
      <key>WorkingDirectory</key>
      <string>#{HOMEBREW_PREFIX}</string>
      <key>StandardErrorPath</key>
      <string>#{var}/log/mongodb/output.log</string>
      <key>StandardOutPath</key>
      <string>#{var}/log/mongodb/output.log</string>
      <key>HardResourceLimits</key>
      <dict>
        <key>NumberOfFiles</key>
        <integer>1024</integer>
      </dict>
      <key>SoftResourceLimits</key>
      <dict>
        <key>NumberOfFiles</key>
        <integer>1024</integer>
      </dict>
    </dict>
    </plist>
    EOS
  end

  test do
    system "#{bin}/mongod", "--sysinfo"
  end
end
