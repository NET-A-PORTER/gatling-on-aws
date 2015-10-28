import java.io.{File, FileReader, BufferedReader}

import io.gatling.core.feeder.Feeder

import scala.util.{Success, Try}

class CircularFeeder[T](var baseFeeder:Feeder[T],factory: => Feeder[T]) extends Feeder[T] {
  override def hasNext: Boolean = true
  override def next = {
      if (!baseFeeder.hasNext)
        baseFeeder = factory
      baseFeeder.next()
    }
}

class SignificantlyLessShitTSVParser(path: String) extends Feeder[String] {
  private val in = new BufferedReader(new FileReader(new File(path)))
  private val columns = in.readLine().split("\t")
  var rsp = input

  private def input: Stream[Map[String,String]] = Try(in.readLine) match {
    case Success(s) if s != null =>
      val out = columns.zip(s.split("\t")).toMap
      out #:: input
    case _ => in.close()
      Stream.empty[Map[String,String]]
  }

  override def hasNext: Boolean = rsp match {
    case h #:: t => true
    case _ => false
  }

  override def next(): Map[String,String] = rsp match {
    case h #:: t => rsp = t
      h
    case _ => ???
  }

  def circular: Feeder[String] = new CircularFeeder(this,new SignificantlyLessShitTSVParser(path))
}
