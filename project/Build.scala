import sbt._
import Keys._
import play.Project._

object ApplicationBuild extends Build {

  val appName         = "AppyBirdDay"
  val appVersion      = "0.3"
	val scalaVersion		= "2.10.1"

  val appDependencies = Seq(
	"org.reactivemongo" %% "play2-reactivemongo" % "0.9",
    // Add your project dependencies here,
	"org.ccil.cowan.tagsoup" % "tagsoup" % "1.2",
    jdbc,
    anorm
  )


  val main = play.Project(appName, appVersion, appDependencies).settings(
    // Add your own project settings here
		playAssetsDirectories <+= baseDirectory / "/build",
		playAssetsDirectories <+= baseDirectory / "/packages",
		playAssetsDirectories <+= baseDirectory / "/web"
  )


	
}
