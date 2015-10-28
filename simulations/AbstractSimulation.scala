import io.gatling.core.Predef._
import io.gatling.core.session.{Expression, Session}
import io.gatling.http.Predef._
import io.gatling.http.request.builder.HttpRequestBuilder
import io.gatling.http.request.{HttpRequest, ExtraInfo}
import io.gatling.core.result.message.KO
import scala.concurrent.duration._

trait AbstractSimulation extends Simulation {

  val users = sys.props.get("test.users").getOrElse("10").toInt
  val baseUrl = sys.props.get("test.baseUrl").get
  val duration = sys.props.get("test.duration").getOrElse("600").toInt
  val instanceCount = sys.props.get("test.instanceCount").getOrElse("1").toInt
  val loadMultiplier = sys.props.get("test.loadMultiplier").getOrElse("1.0").toDouble

  val pickUrlPercent = 0.01

  val httpConf = http
    .baseURL(baseUrl)
    .acceptHeader("*/*")
    .acceptEncodingHeader("gzip")
    .disableCaching
    .disableFollowRedirect
    .disableUrlEncoding
    .userAgentHeader("llt/1.0")
    // Log the request/response for all failures in simulation.log
    .extraInfoExtractor {
    case ExtraInfo(_, KO, _, req, res) => req.getUrl :: " " :: res.body :: Nil
    case _ => Nil
  }

  def scaledRps(rps: Int) = {
    val instanceScalingFactor = loadMultiplier/instanceCount
    (rps * instanceScalingFactor).toInt
  }

  def scn: io.gatling.core.structure.ScenarioBuilder

  def simulation = scn.inject(atOnceUsers(users))

  setUp(simulation)
    .protocols(httpConf)
    .maxDuration(duration.seconds)

  private val regex = """=""".r.anchored

  def splitParam(a: String) = regex.split(a) match {
    case Array(k, v) => k -> v
  }

}
