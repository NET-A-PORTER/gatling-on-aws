import io.gatling.core.Predef._
import io.gatling.http.Predef._
import scala.concurrent.duration._

abstract class ReplaySimulation extends AbstractSimulation {
  def dataFile: String
  def userBehaviour = exec(http("${name}").get("${url}")

  override def scn = scenario("Replay Live Logs")
    .forever {
      feed(new SignificantlyLessShitTSVParser(s"data/$dataFile").circular)
        .exec(userBehaviour)
    }
}
