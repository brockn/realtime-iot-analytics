import org.apache.spark.{SparkConf, SparkContext};
import org.apache.spark.streaming.kafka._
import org.apache.spark.streaming.{Seconds, StreamingContext}
import kafka.serializer.StringDecoder
import org.json4s._
import org.json4s.jackson.JsonMethods._;
import scalaj.http.Http;
import scala.math;

object CustomSparkHandler {
  def main(args: Array[String]) {
    val conf = new SparkConf().setAppName(this.getClass.getSimpleName);
    val sc = new SparkContext(conf);
    val ssc = new StreamingContext(sc, Seconds(5));
    val topicsSet = "CRASH_EVENTS".split(",").toSet
    val kafkaParams = Map[String, String]("metadata.broker.list" -> "TODO")
    val data = KafkaUtils.createDirectStream[String, String, StringDecoder, StringDecoder](ssc, kafkaParams, topicsSet).map(_._2).map({raw => 
      raw
    });
    data.saveAsTextFiles("/tmp/crash_events/output");
    data.foreachRDD{ rdd =>
      rdd.foreachPartition { records =>
        var maxXValue = 0.0d
        var maxYValue = 0.0d
        var maxZValue = 0.0d
        records.foreach{ raw =>
          var record = parse(raw).asInstanceOf[JObject].values
          maxXValue = math.max(maxXValue, record{"x"}.asInstanceOf[Double])
          maxYValue = math.max(maxYValue, record{"y"}.asInstanceOf[Double])
          maxZValue = math.max(maxZValue, record{"z"}.asInstanceOf[Double])
        }
        def alert(name:String, value:Double) {
          var valueFormatted = math.round(value * 100) / 100.0d
          var url = "https://events.pagerduty.com/generic/2010-04-15/create_event.json"
          var msg = s"""{
            "service_key": "TODO",
            "event_type": "trigger",
            "description": "Value ${name} exceeded threshold: ${valueFormatted}"
          }"""
          Http(url).postData(msg).header("content-type", "application/json").asString.code
        }
        if (maxXValue > 6) {
          alert("X", maxXValue);
        }
        if (maxYValue > 6) {
          alert("Y", maxYValue);
        }
        if (maxZValue > 6) {
          alert("Z", maxZValue);
        }
      }
    }
    ssc.start();
    ssc.awaitTermination();
  }
}
